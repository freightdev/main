// ================================================================
// OPENHWY TMS - RUST BACKEND API
// ================================================================
// Cargo.toml dependencies needed:
// 
// [dependencies]
// actix-web = "4.4"
// actix-cors = "0.7"
// tokio = { version = "1.35", features = ["full"] }
// sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-rustls", "uuid", "chrono", "json"] }
// serde = { version = "1.0", features = ["derive"] }
// serde_json = "1.0"
// uuid = { version = "1.6", features = ["serde", "v4"] }
// chrono = { version = "0.4", features = ["serde"] }
// dotenv = "0.15"
// jsonwebtoken = "9.2"
// bcrypt = "0.15"
// redis = { version = "0.24", features = ["tokio-comp", "connection-manager"] }
// deadpool-redis = "0.14"
// geo = "0.27"
// geojson = "0.24"
// thiserror = "1.0"
// tracing = "0.1"
// tracing-subscriber = "0.3"
// validator = { version = "0.16", features = ["derive"] }
// ================================================================

use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, FromRow, postgres::PgPoolOptions};
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDate};
use std::sync::Arc;

// ================================================================
// ERROR HANDLING
// ================================================================

use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    
    #[error("Not found: {0}")]
    NotFound(String),
    
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("Authentication error: {0}")]
    AuthError(String),
    
    #[error("Business logic error: {0}")]
    BusinessLogicError(String),
}

impl actix_web::error::ResponseError for ApiError {
    fn error_response(&self) -> HttpResponse {
        match self {
            ApiError::NotFound(msg) => HttpResponse::NotFound().json(serde_json::json!({
                "error": "not_found",
                "message": msg
            })),
            ApiError::ValidationError(msg) => HttpResponse::BadRequest().json(serde_json::json!({
                "error": "validation_error",
                "message": msg
            })),
            ApiError::AuthError(msg) => HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "unauthorized",
                "message": msg
            })),
            _ => HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "internal_server_error",
                "message": self.to_string()
            })),
        }
    }
}

type ApiResult<T> = Result<T, ApiError>;

// ================================================================
// APPLICATION STATE
// ================================================================

pub struct AppState {
    pub db: PgPool,
    pub redis: deadpool_redis::Pool,
}

// ================================================================
// MODELS - LOADS
// ================================================================

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Load {
    pub id: Uuid,
    pub company_id: Uuid,
    pub load_number: String,
    pub reference_number: Option<String>,
    pub bol_number: Option<String>,
    pub load_type: String,
    pub mode: String,
    pub customer_id: Option<Uuid>,
    pub carrier_id: Option<Uuid>,
    pub truck_id: Option<Uuid>,
    pub trailer_id: Option<Uuid>,
    pub driver_id: Option<Uuid>,
    pub equipment_type: Option<String>,
    pub total_weight_lbs: Option<i32>,
    pub total_pieces: Option<i32>,
    pub commodity_description: Option<String>,
    pub status: String,
    pub pickup_date: NaiveDate,
    pub delivery_date: NaiveDate,
    pub customer_rate: Option<f64>,
    pub carrier_rate: Option<f64>,
    pub total_revenue: Option<f64>,
    pub total_cost: Option<f64>,
    pub profit_margin: Option<f64>,
    pub total_miles: Option<i32>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateLoadRequest {
    #[validate(length(min = 1))]
    pub load_number: String,
    pub reference_number: Option<String>,
    pub load_type: String,
    pub customer_id: Uuid,
    pub equipment_type: String,
    pub pickup_date: NaiveDate,
    pub delivery_date: NaiveDate,
    pub total_weight_lbs: Option<i32>,
    pub commodity_description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateLoadRequest {
    pub status: Option<String>,
    pub driver_id: Option<Uuid>,
    pub truck_id: Option<Uuid>,
    pub trailer_id: Option<Uuid>,
    pub customer_rate: Option<f64>,
    pub carrier_rate: Option<f64>,
}

// ================================================================
// MODELS - DRIVERS
// ================================================================

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Driver {
    pub id: Uuid,
    pub company_id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: Option<String>,
    pub phone: String,
    pub cdl_number: String,
    pub cdl_state: Option<String>,
    pub cdl_class: Option<String>,
    pub cdl_expiry: NaiveDate,
    pub employment_status: String,
    pub current_status: String,
    pub total_miles: i64,
    pub total_loads: i32,
    pub safety_score: Option<f64>,
    pub on_time_percentage: Option<f64>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateDriverRequest {
    pub first_name: String,
    pub last_name: String,
    pub phone: String,
    pub email: Option<String>,
    pub cdl_number: String,
    pub cdl_state: String,
    pub cdl_class: String,
    pub cdl_expiry: NaiveDate,
    pub hire_date: Option<NaiveDate>,
    pub pay_type: String,
    pub pay_rate: f64,
}

#[derive(Debug, Deserialize)]
pub struct UpdateDriverLocationRequest {
    pub latitude: f64,
    pub longitude: f64,
    pub status: String,
}

// ================================================================
// MODELS - CUSTOMERS
// ================================================================

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Customer {
    pub id: Uuid,
    pub company_id: Uuid,
    pub customer_name: String,
    pub customer_type: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub payment_terms: i32,
    pub credit_limit: Option<f64>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ================================================================
// MODELS - INVOICES
// ================================================================

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Invoice {
    pub id: Uuid,
    pub company_id: Uuid,
    pub invoice_number: String,
    pub invoice_type: String,
    pub customer_id: Option<Uuid>,
    pub load_id: Option<Uuid>,
    pub total_amount: f64,
    pub amount_paid: f64,
    pub balance_due: f64,
    pub invoice_date: NaiveDate,
    pub due_date: NaiveDate,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

// ================================================================
// DATABASE OPERATIONS - LOADS
// ================================================================

pub struct LoadRepository;

impl LoadRepository {
    pub async fn create(pool: &PgPool, company_id: Uuid, req: CreateLoadRequest) -> ApiResult<Load> {
        let load = sqlx::query_as::<_, Load>(
            r#"
            INSERT INTO loads (
                company_id, load_number, reference_number, load_type,
                customer_id, equipment_type, pickup_date, delivery_date,
                total_weight_lbs, commodity_description, status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'pending')
            RETURNING *
            "#
        )
        .bind(company_id)
        .bind(&req.load_number)
        .bind(&req.reference_number)
        .bind(&req.load_type)
        .bind(req.customer_id)
        .bind(&req.equipment_type)
        .bind(req.pickup_date)
        .bind(req.delivery_date)
        .bind(req.total_weight_lbs)
        .bind(&req.commodity_description)
        .fetch_one(pool)
        .await?;
        
        Ok(load)
    }
    
    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> ApiResult<Load> {
        let load = sqlx::query_as::<_, Load>("SELECT * FROM loads WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| ApiError::NotFound(format!("Load with id {} not found", id)))?;
        
        Ok(load)
    }
    
    pub async fn list_active(pool: &PgPool, company_id: Uuid) -> ApiResult<Vec<Load>> {
        let loads = sqlx::query_as::<_, Load>(
            r#"
            SELECT * FROM loads 
            WHERE company_id = $1 
            AND status NOT IN ('delivered', 'completed', 'cancelled')
            ORDER BY pickup_date ASC
            "#
        )
        .bind(company_id)
        .fetch_all(pool)
        .await?;
        
        Ok(loads)
    }
    
    pub async fn update_status(pool: &PgPool, id: Uuid, status: String) -> ApiResult<Load> {
        let load = sqlx::query_as::<_, Load>(
            "UPDATE loads SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *"
        )
        .bind(&status)
        .bind(id)
        .fetch_one(pool)
        .await?;
        
        Ok(load)
    }
    
    pub async fn assign_driver(pool: &PgPool, load_id: Uuid, driver_id: Uuid, truck_id: Uuid, trailer_id: Option<Uuid>) -> ApiResult<Load> {
        let load = sqlx::query_as::<_, Load>(
            r#"
            UPDATE loads 
            SET driver_id = $1, truck_id = $2, trailer_id = $3, status = 'dispatched', updated_at = NOW()
            WHERE id = $4
            RETURNING *
            "#
        )
        .bind(driver_id)
        .bind(truck_id)
        .bind(trailer_id)
        .bind(load_id)
        .fetch_one(pool)
        .await?;
        
        Ok(load)
    }
    
    pub async fn get_financial_summary(pool: &PgPool, company_id: Uuid, start_date: NaiveDate, end_date: NaiveDate) -> ApiResult<FinancialSummary> {
        let summary = sqlx::query_as::<_, FinancialSummary>(
            r#"
            SELECT 
                COUNT(*) as total_loads,
                COALESCE(SUM(total_revenue), 0) as total_revenue,
                COALESCE(SUM(total_cost), 0) as total_cost,
                COALESCE(SUM(profit_margin), 0) as total_profit,
                COALESCE(SUM(total_miles), 0) as total_miles
            FROM loads
            WHERE company_id = $1
            AND pickup_date BETWEEN $2 AND $3
            AND status IN ('delivered', 'completed')
            "#
        )
        .bind(company_id)
        .bind(start_date)
        .bind(end_date)
        .fetch_one(pool)
        .await?;
        
        Ok(summary)
    }
}

#[derive(Debug, Serialize, FromRow)]
pub struct FinancialSummary {
    pub total_loads: i64,
    pub total_revenue: f64,
    pub total_cost: f64,
    pub total_profit: f64,
    pub total_miles: i64,
}

// ================================================================
// DATABASE OPERATIONS - DRIVERS
// ================================================================

pub struct DriverRepository;

impl DriverRepository {
    pub async fn create(pool: &PgPool, company_id: Uuid, req: CreateDriverRequest) -> ApiResult<Driver> {
        let driver = sqlx::query_as::<_, Driver>(
            r#"
            INSERT INTO drivers (
                company_id, first_name, last_name, phone, email,
                cdl_number, cdl_state, cdl_class, cdl_expiry,
                hire_date, pay_type, pay_rate, employment_status, current_status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'active', 'off_duty')
            RETURNING id, company_id, first_name, last_name, email, phone,
                      cdl_number, cdl_state, cdl_class, cdl_expiry,
                      employment_status, current_status, total_miles, total_loads,
                      safety_score, on_time_percentage, created_at, updated_at
            "#
        )
        .bind(company_id)
        .bind(&req.first_name)
        .bind(&req.last_name)
        .bind(&req.phone)
        .bind(&req.email)
        .bind(&req.cdl_number)
        .bind(&req.cdl_state)
        .bind(&req.cdl_class)
        .bind(req.cdl_expiry)
        .bind(req.hire_date)
        .bind(&req.pay_type)
        .bind(req.pay_rate)
        .fetch_one(pool)
        .await?;
        
        Ok(driver)
    }
    
    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> ApiResult<Driver> {
        let driver = sqlx::query_as::<_, Driver>("SELECT * FROM drivers WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| ApiError::NotFound(format!("Driver with id {} not found", id)))?;
        
        Ok(driver)
    }
    
    pub async fn list_available(pool: &PgPool, company_id: Uuid) -> ApiResult<Vec<Driver>> {
        let drivers = sqlx::query_as::<_, Driver>(
            r#"
            SELECT * FROM drivers 
            WHERE company_id = $1 
            AND employment_status = 'active'
            AND current_status IN ('available', 'off_duty')
            ORDER BY first_name, last_name
            "#
        )
        .bind(company_id)
        .fetch_all(pool)
        .await?;
        
        Ok(drivers)
    }
    
    pub async fn update_location(pool: &PgPool, id: Uuid, req: UpdateDriverLocationRequest) -> ApiResult<()> {
        sqlx::query(
            r#"
            UPDATE drivers 
            SET current_location = ST_SetSRID(ST_MakePoint($1, $2), 4326),
                current_status = $3,
                last_location_update = NOW()
            WHERE id = $4
            "#
        )
        .bind(req.longitude)
        .bind(req.latitude)
        .bind(&req.status)
        .bind(id)
        .execute(pool)
        .await?;
        
        Ok(())
    }
}

// ================================================================
// API HANDLERS - LOADS
// ================================================================

pub async fn create_load(
    state: web::Data<Arc<AppState>>,
    req: web::Json<CreateLoadRequest>,
    company_id: web::Path<Uuid>,
) -> ApiResult<impl Responder> {
    let load = LoadRepository::create(&state.db, *company_id, req.into_inner()).await?;
    Ok(HttpResponse::Created().json(load))
}

pub async fn get_load(
    state: web::Data<Arc<AppState>>,
    load_id: web::Path<Uuid>,
) -> ApiResult<impl Responder> {
    let load = LoadRepository::find_by_id(&state.db, *load_id).await?;
    Ok(HttpResponse::Ok().json(load))
}

pub async fn list_active_loads(
    state: web::Data<Arc<AppState>>,
    company_id: web::Path<Uuid>,
) -> ApiResult<impl Responder> {
    let loads = LoadRepository::list_active(&state.db, *company_id).await?;
    Ok(HttpResponse::Ok().json(loads))
}

pub async fn update_load_status(
    state: web::Data<Arc<AppState>>,
    path: web::Path<(Uuid, String)>,
) -> ApiResult<impl Responder> {
    let (load_id, status) = path.into_inner();
    let load = LoadRepository::update_status(&state.db, load_id, status).await?;
    Ok(HttpResponse::Ok().json(load))
}

pub async fn assign_driver_to_load(
    state: web::Data<Arc<AppState>>,
    load_id: web::Path<Uuid>,
    req: web::Json<AssignDriverRequest>,
) -> ApiResult<impl Responder> {
    let load = LoadRepository::assign_driver(
        &state.db,
        *load_id,
        req.driver_id,
        req.truck_id,
        req.trailer_id,
    ).await?;
    Ok(HttpResponse::Ok().json(load))
}

#[derive(Debug, Deserialize)]
pub struct AssignDriverRequest {
    pub driver_id: Uuid,
    pub truck_id: Uuid,
    pub trailer_id: Option<Uuid>,
}

// ================================================================
// API HANDLERS - DRIVERS
// ================================================================

pub async fn create_driver(
    state: web::Data<Arc<AppState>>,
    company_id: web::Path<Uuid>,
    req: web::Json<CreateDriverRequest>,
) -> ApiResult<impl Responder> {
    let driver = DriverRepository::create(&state.db, *company_id, req.into_inner()).await?;
    Ok(HttpResponse::Created().json(driver))
}

pub async fn get_driver(
    state: web::Data<Arc<AppState>>,
    driver_id: web::Path<Uuid>,
) -> ApiResult<impl Responder> {
    let driver = DriverRepository::find_by_id(&state.db, *driver_id).await?;
    Ok(HttpResponse::Ok().json(driver))
}

pub async fn list_available_drivers(
    state: web::Data<Arc<AppState>>,
    company_id: web::Path<Uuid>,
) -> ApiResult<impl Responder> {
    let drivers = DriverRepository::list_available(&state.db, *company_id).await?;
    Ok(HttpResponse::Ok().json(drivers))
}

pub async fn update_driver_location(
    state: web::Data<Arc<AppState>>,
    driver_id: web::Path<Uuid>,
    req: web::Json<UpdateDriverLocationRequest>,
) -> ApiResult<impl Responder> {
    DriverRepository::update_location(&state.db, *driver_id, req.into_inner()).await?;
    Ok(HttpResponse::Ok().json(serde_json::json!({ "status": "updated" })))
}

// ================================================================
// MAIN APPLICATION SETUP
// ================================================================

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    // Load environment variables
    dotenv::dotenv().ok();
    
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    // Create database connection pool
    let pool = PgPoolOptions::new()
        .max_connections(20)
        .connect(&database_url)
        .await
        .expect("Failed to create pool");
    
    // Create Redis connection pool
    let redis_url = std::env::var("REDIS_URL")
        .unwrap_or_else(|_| "redis://127.0.0.1/".to_string());
    
    let redis_cfg = deadpool_redis::Config::from_url(redis_url);
    let redis = redis_cfg.create_pool(Some(deadpool_redis::Runtime::Tokio1))
        .expect("Failed to create Redis pool");
    
    let app_state = Arc::new(AppState { db: pool, redis });
    
    println!("🚀 OpenHWY TMS API Server starting on http://0.0.0.0:8080");
    
    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(app_state.clone()))
            .wrap(actix_cors::Cors::permissive())
            .route("/health", web::get().to(health_check))
            // Load routes
            .route("/api/companies/{company_id}/loads", web::post().to(create_load))
            .route("/api/companies/{company_id}/loads", web::get().to(list_active_loads))
            .route("/api/loads/{load_id}", web::get().to(get_load))
            .route("/api/loads/{load_id}/status/{status}", web::patch().to(update_load_status))
            .route("/api/loads/{load_id}/assign", web::post().to(assign_driver_to_load))
            // Driver routes
            .route("/api/companies/{company_id}/drivers", web::post().to(create_driver))
            .route("/api/companies/{company_id}/drivers/available", web::get().to(list_available_drivers))
            .route("/api/drivers/{driver_id}", web::get().to(get_driver))
            .route("/api/drivers/{driver_id}/location", web::patch().to(update_driver_location))
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}

async fn health_check() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "openhwy-tms-api",
        "version": "1.0.0"
    }))
}
