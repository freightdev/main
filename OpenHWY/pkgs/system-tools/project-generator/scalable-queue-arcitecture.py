"""
Scalable Queue-Based Architecture for Project Generator
Handles 100+ customers with 3-laptop cluster
"""

import redis
import json
import time
import uuid
from enum import Enum
from dataclasses import dataclass, asdict
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import asyncio
import aiohttp
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.responses import JSONResponse
import logging

# ============================================================================
# CONFIGURATION
# ============================================================================

class QueueConfig:
    REDIS_HOST = "localhost"
    REDIS_PORT = 6379
    REDIS_DB = 0
    
    # Queue names
    QUEUE_PENDING = "projects:pending"
    QUEUE_PROCESSING = "projects:processing"
    QUEUE_COMPLETED = "projects:completed"
    QUEUE_FAILED = "projects:failed"
    
    # Concurrency limits (realistic for 3 laptops)
    MAX_CONCURRENT_JOBS = 3
    MAX_QUEUE_SIZE = 1000
    
    # Priority tiers (lower = higher priority)
    PRIORITY_ENTERPRISE = 0
    PRIORITY_PRO = 1
    PRIORITY_INDIE = 2
    PRIORITY_FREE = 3
    
    # Timeouts
    JOB_TIMEOUT_SECONDS = 3600  # 1 hour max
    POSITION_ESTIMATE_SECONDS = 600  # 10 min per job estimate

# ============================================================================
# DATA MODELS
# ============================================================================

class JobStatus(Enum):
    QUEUED = "queued"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class TierLimits(Enum):
    FREE = {"concurrent": 1, "queue_priority": 3, "monthly_limit": 1}
    INDIE = {"concurrent": 2, "queue_priority": 2, "monthly_limit": 10}
    PRO = {"concurrent": 3, "queue_priority": 1, "monthly_limit": -1}  # unlimited
    ENTERPRISE = {"concurrent": 5, "queue_priority": 0, "monthly_limit": -1}

@dataclass
class ProjectJob:
    job_id: str
    user_id: str
    tier: str
    project_schema: Dict[str, Any]
    status: JobStatus
    priority: int
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None
    result_url: Optional[str] = None
    queue_position: Optional[int] = None
    estimated_start: Optional[datetime] = None
    worker_id: Optional[str] = None

# ============================================================================
# QUEUE MANAGER
# ============================================================================

class QueueManager:
    """Manages job queue with Redis"""
    
    def __init__(self):
        self.redis = redis.Redis(
            host=QueueConfig.REDIS_HOST,
            port=QueueConfig.REDIS_PORT,
            db=QueueConfig.REDIS_DB,
            decode_responses=True
        )
        self.logger = logging.getLogger("QueueManager")
    
    def submit_job(self, job: ProjectJob) -> Dict[str, Any]:
        """Submit job to queue"""
        
        # Check queue size limit
        queue_size = self.redis.llen(QueueConfig.QUEUE_PENDING)
        if queue_size >= QueueConfig.MAX_QUEUE_SIZE:
            raise Exception("Queue is full. Please try again later.")
        
        # Check user's monthly limit
        if not self._check_user_limit(job.user_id, job.tier):
            raise Exception("Monthly project limit reached. Please upgrade.")
        
        # Serialize job
        job_data = self._serialize_job(job)
        
        # Add to sorted set by priority (lower score = higher priority)
        score = job.priority * 1000000 + time.time()
        self.redis.zadd(QueueConfig.QUEUE_PENDING, {job.job_id: score})
        
        # Store job details
        self.redis.hset(f"job:{job.job_id}", mapping=job_data)
        
        # Track user's jobs this month
        month_key = f"user:{job.user_id}:jobs:{datetime.now().strftime('%Y-%m')}"
        self.redis.incr(month_key)
        self.redis.expire(month_key, 2592000)  # 30 days
        
        # Calculate position and estimate
        position = self._get_queue_position(job.job_id)
        estimated_start = self._estimate_start_time(position)
        
        self.logger.info(f"Job {job.job_id} queued at position {position}")
        
        return {
            "job_id": job.job_id,
            "status": "queued",
            "queue_position": position,
            "estimated_start": estimated_start.isoformat(),
            "estimated_wait_minutes": position * 10  # 10 min per job estimate
        }
    
    def get_next_job(self, worker_id: str) -> Optional[ProjectJob]:
        """Get next job from queue (highest priority)"""
        
        # Check if we're at concurrency limit
        processing = self.redis.llen(QueueConfig.QUEUE_PROCESSING)
        if processing >= QueueConfig.MAX_CONCURRENT_JOBS:
            return None
        
        # Get highest priority job (lowest score)
        jobs = self.redis.zrange(QueueConfig.QUEUE_PENDING, 0, 0, withscores=True)
        
        if not jobs:
            return None
        
        job_id, score = jobs[0]
        
        # Move to processing
        self.redis.zrem(QueueConfig.QUEUE_PENDING, job_id)
        self.redis.lpush(QueueConfig.QUEUE_PROCESSING, job_id)
        
        # Load job details
        job_data = self.redis.hgetall(f"job:{job_id}")
        job = self._deserialize_job(job_data)
        
        # Update job
        job.status = JobStatus.PROCESSING
        job.started_at = datetime.now()
        job.worker_id = worker_id
        
        # Save updated job
        self.redis.hset(f"job:{job_id}", mapping=self._serialize_job(job))
        
        # Set timeout
        self.redis.setex(
            f"job:{job_id}:timeout",
            QueueConfig.JOB_TIMEOUT_SECONDS,
            "1"
        )
        
        self.logger.info(f"Job {job_id} started on worker {worker_id}")
        
        return job
    
    def complete_job(self, job_id: str, result_url: str):
        """Mark job as completed"""
        
        # Remove from processing
        self.redis.lrem(QueueConfig.QUEUE_PROCESSING, 0, job_id)
        
        # Update job
        job_data = self.redis.hgetall(f"job:{job_id}")
        job = self._deserialize_job(job_data)
        
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.now()
        job.result_url = result_url
        
        self.redis.hset(f"job:{job_id}", mapping=self._serialize_job(job))
        
        # Add to completed list (keep for 7 days)
        self.redis.lpush(QueueConfig.QUEUE_COMPLETED, job_id)
        self.redis.expire(f"job:{job_id}", 604800)  # 7 days
        
        self.logger.info(f"Job {job_id} completed")
        
        # Send notification to user
        self._notify_user(job.user_id, job_id, "completed", result_url)
    
    def fail_job(self, job_id: str, error: str):
        """Mark job as failed"""
        
        # Remove from processing
        self.redis.lrem(QueueConfig.QUEUE_PROCESSING, 0, job_id)
        
        # Update job
        job_data = self.redis.hgetall(f"job:{job_id}")
        job = self._deserialize_job(job_data)
        
        job.status = JobStatus.FAILED
        job.completed_at = datetime.now()
        job.error_message = error
        
        self.redis.hset(f"job:{job_id}", mapping=self._serialize_job(job))
        
        # Add to failed list
        self.redis.lpush(QueueConfig.QUEUE_FAILED, job_id)
        
        self.logger.error(f"Job {job_id} failed: {error}")
        
        # Send notification to user
        self._notify_user(job.user_id, job_id, "failed", error)
    
    def get_job_status(self, job_id: str) -> Dict[str, Any]:
        """Get current job status"""
        
        job_data = self.redis.hgetall(f"job:{job_id}")
        
        if not job_data:
            raise HTTPException(status_code=404, detail="Job not found")
        
        job = self._deserialize_job(job_data)
        
        response = {
            "job_id": job.job_id,
            "status": job.status.value,
            "created_at": job.created_at.isoformat(),
        }
        
        if job.status == JobStatus.QUEUED:
            position = self._get_queue_position(job_id)
            estimated_start = self._estimate_start_time(position)
            response.update({
                "queue_position": position,
                "estimated_start": estimated_start.isoformat(),
                "estimated_wait_minutes": position * 10
            })
        
        elif job.status == JobStatus.PROCESSING:
            elapsed = (datetime.now() - job.started_at).seconds
            response.update({
                "started_at": job.started_at.isoformat(),
                "elapsed_seconds": elapsed,
                "worker_id": job.worker_id
            })
        
        elif job.status == JobStatus.COMPLETED:
            response.update({
                "completed_at": job.completed_at.isoformat(),
                "result_url": job.result_url,
                "duration_seconds": (job.completed_at - job.started_at).seconds
            })
        
        elif job.status == JobStatus.FAILED:
            response.update({
                "completed_at": job.completed_at.isoformat(),
                "error": job.error_message
            })
        
        return response
    
    def get_queue_stats(self) -> Dict[str, Any]:
        """Get overall queue statistics"""
        
        return {
            "pending": self.redis.zcard(QueueConfig.QUEUE_PENDING),
            "processing": self.redis.llen(QueueConfig.QUEUE_PROCESSING),
            "completed_today": self._get_completed_today(),
            "failed_today": self._get_failed_today(),
            "avg_processing_time_minutes": self._get_avg_processing_time(),
            "estimated_wait_minutes": self._estimate_wait_time()
        }
    
    def _check_user_limit(self, user_id: str, tier: str) -> bool:
        """Check if user is within monthly limit"""
        
        limits = TierLimits[tier.upper()].value
        monthly_limit = limits["monthly_limit"]
        
        if monthly_limit == -1:  # Unlimited
            return True
        
        month_key = f"user:{user_id}:jobs:{datetime.now().strftime('%Y-%m')}"
        current_count = int(self.redis.get(month_key) or 0)
        
        return current_count < monthly_limit
    
    def _get_queue_position(self, job_id: str) -> int:
        """Get position in queue (1-indexed)"""
        rank = self.redis.zrank(QueueConfig.QUEUE_PENDING, job_id)
        return rank + 1 if rank is not None else 0
    
    def _estimate_start_time(self, position: int) -> datetime:
        """Estimate when job will start based on position"""
        
        # Assume 10 minutes per job on average
        minutes_until_start = position * QueueConfig.POSITION_ESTIMATE_SECONDS / 60
        return datetime.now() + timedelta(minutes=minutes_until_start)
    
    def _estimate_wait_time(self) -> int:
        """Estimate average wait time in minutes"""
        pending = self.redis.zcard(QueueConfig.QUEUE_PENDING)
        return (pending // QueueConfig.MAX_CONCURRENT_JOBS) * 10
    
    def _get_completed_today(self) -> int:
        """Get number of completed jobs today"""
        # Simplified - would need time-series data for accuracy
        return self.redis.llen(QueueConfig.QUEUE_COMPLETED)
    
    def _get_failed_today(self) -> int:
        """Get number of failed jobs today"""
        return self.redis.llen(QueueConfig.QUEUE_FAILED)
    
    def _get_avg_processing_time(self) -> float:
        """Get average processing time"""
        # Simplified - would calculate from recent completed jobs
        return 12.5  # 12.5 minutes average
    
    def _serialize_job(self, job: ProjectJob) -> Dict[str, str]:
        """Serialize job to Redis-compatible format"""
        data = asdict(job)
        data["status"] = job.status.value
        data["created_at"] = job.created_at.isoformat()
        data["started_at"] = job.started_at.isoformat() if job.started_at else ""
        data["completed_at"] = job.completed_at.isoformat() if job.completed_at else ""
        data["project_schema"] = json.dumps(job.project_schema)
        return {k: str(v) for k, v in data.items()}
    
    def _deserialize_job(self, data: Dict[str, str]) -> ProjectJob:
        """Deserialize job from Redis"""
        return ProjectJob(
            job_id=data["job_id"],
            user_id=data["user_id"],
            tier=data["tier"],
            project_schema=json.loads(data["project_schema"]),
            status=JobStatus(data["status"]),
            priority=int(data["priority"]),
            created_at=datetime.fromisoformat(data["created_at"]),
            started_at=datetime.fromisoformat(data["started_at"]) if data.get("started_at") else None,
            completed_at=datetime.fromisoformat(data["completed_at"]) if data.get("completed_at") else None,
            error_message=data.get("error_message"),
            result_url=data.get("result_url"),
            worker_id=data.get("worker_id")
        )
    
    def _notify_user(self, user_id: str, job_id: str, status: str, detail: str):
        """Send notification to user (webhook/email/websocket)"""
        # TODO: Implement notification system
        self.logger.info(f"Notify user {user_id}: Job {job_id} is {status}")

# ============================================================================
# WORKER
# ============================================================================

class Worker:
    """Worker process that pulls jobs from queue and processes them"""
    
    def __init__(self, worker_id: str, ollama_cluster_config: Dict):
        self.worker_id = worker_id
        self.queue = QueueManager()
        self.ollama_config = ollama_cluster_config
        self.logger = logging.getLogger(f"Worker-{worker_id}")
        self.running = False
    
    async def start(self):
        """Start worker loop"""
        self.running = True
        self.logger.info(f"Worker {self.worker_id} started")
        
        while self.running:
            try:
                # Get next job
                job = self.queue.get_next_job(self.worker_id)
                
                if job:
                    self.logger.info(f"Processing job {job.job_id}")
                    
                    try:
                        # Process the job
                        result_url = await self._process_project(job)
                        
                        # Mark as completed
                        self.queue.complete_job(job.job_id, result_url)
                        
                    except Exception as e:
                        self.logger.error(f"Job {job.job_id} failed: {e}")
                        self.queue.fail_job(job.job_id, str(e))
                
                else:
                    # No jobs available, wait
                    await asyncio.sleep(5)
            
            except Exception as e:
                self.logger.error(f"Worker error: {e}")
                await asyncio.sleep(10)
    
    async def _process_project(self, job: ProjectJob) -> str:
        """Actually generate the project"""
        
        # Import your ProjectGenerator
        from src.workflow.builder import WorkflowBuilder
        from src.core.schemas import ProjectSchema
        from src.core.config import ClusterConfig
        
        # Create schema from job data
        schema = ProjectSchema(**job.project_schema)
        
        # Load cluster config
        cluster = ClusterConfig.from_yaml("config/cluster_config.yaml")
        
        # Generate project
        builder = WorkflowBuilder(schema, cluster)
        result = builder.generate()
        
        # Upload to storage and return URL
        result_url = await self._upload_result(job.job_id, result)
        
        return result_url
    
    async def _upload_result(self, job_id: str, result) -> str:
        """Upload generated project to SeaweedFS"""
        # TODO: Implement upload to SeaweedFS
        return f"https://storage.yourcloud.com/projects/{job_id}.zip"
    
    def stop(self):
        """Stop worker gracefully"""
        self.running = False
        self.logger.info(f"Worker {self.worker_id} stopping")

# ============================================================================
# API
# ============================================================================

app = FastAPI(title="Project Generator API")
queue_manager = QueueManager()

@app.post("/api/v1/projects")
async def create_project(
    user_id: str,
    tier: str,
    project_schema: Dict[str, Any]
):
    """Submit project generation job"""
    
    try:
        # Create job
        job = ProjectJob(
            job_id=str(uuid.uuid4()),
            user_id=user_id,
            tier=tier,
            project_schema=project_schema,
            status=JobStatus.QUEUED,
            priority=QueueConfig.__dict__[f"PRIORITY_{tier.upper()}"],
            created_at=datetime.now()
        )
        
        # Submit to queue
        result = queue_manager.submit_job(job)
        
        return JSONResponse(status_code=202, content=result)
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/api/v1/projects/{job_id}")
async def get_project_status(job_id: str):
    """Get job status"""
    return queue_manager.get_job_status(job_id)

@app.get("/api/v1/queue/stats")
async def get_queue_stats():
    """Get queue statistics"""
    return queue_manager.get_queue_stats()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    # Start workers in background
    workers = []
    for i in range(QueueConfig.MAX_CONCURRENT_JOBS):
        worker = Worker(f"worker-{i}", {})
        workers.append(worker)
        asyncio.create_task(worker.start())
    
    # Start API server
    uvicorn.run(app, host="0.0.0.0", port=8000)