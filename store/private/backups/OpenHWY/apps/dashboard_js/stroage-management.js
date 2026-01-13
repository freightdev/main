import {
  Activity,
  Archive,
  BarChart3,
  Calendar,
  CheckCircle,
  ChevronRight,
  Clock,
  Copy,
  Database,
  Download,
  Edit3,
  File,
  FileAudio,
  FileCode,
  FileImage,
  FileVideo,
  Filter,
  Folder,
  FolderOpen,
  GitBranch,
  Globe,
  Grid,
  HardDrive,
  List,
  MoreVertical,
  Package,
  Plus,
  RefreshCw,
  Search,
  Server,
  Share2,
  Star,
  Trash2,
  TrendingUp,
  Upload,
  Users,
  X,
  Zap,
} from "lucide-react";
import { useState } from "react";

export default function CloudDashStorage() {
  const [activeView, setActiveView] = useState("overview");
  const [viewMode, setViewMode] = useState("grid"); // grid or list
  const [selectedItems, setSelectedItems] = useState([]);
  const [currentPath, setCurrentPath] = useState(["root"]);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [showVolumeModal, setShowVolumeModal] = useState(false);

  // Mock storage data
  const storageStats = {
    totalCapacity: 4096, // GB
    used: 2847, // GB
    available: 1249, // GB
    volumes: 12,
    snapshots: 47,
    backups: 8,
  };

  const volumes = [
    {
      id: "vol-001",
      name: "production-db",
      size: 500,
      used: 342,
      type: "NVMe SSD",
      status: "attached",
      attachedTo: "vm-prod-01",
      created: "2024-01-15",
      snapshots: 12,
      iops: 3000,
      throughput: "250 MB/s",
    },
    {
      id: "vol-002",
      name: "app-storage",
      size: 250,
      used: 187,
      type: "NVMe SSD",
      status: "attached",
      attachedTo: "vm-app-01",
      created: "2024-02-20",
      snapshots: 8,
      iops: 3000,
      throughput: "250 MB/s",
    },
    {
      id: "vol-003",
      name: "backup-volume",
      size: 1000,
      used: 823,
      type: "HDD",
      status: "detached",
      attachedTo: null,
      created: "2024-01-10",
      snapshots: 4,
      iops: 500,
      throughput: "100 MB/s",
    },
    {
      id: "vol-004",
      name: "dev-workspace",
      size: 100,
      used: 45,
      type: "NVMe SSD",
      status: "attached",
      attachedTo: "vm-dev-01",
      created: "2024-03-05",
      snapshots: 15,
      iops: 3000,
      throughput: "250 MB/s",
    },
  ];

  const snapshots = [
    {
      id: "snap-001",
      name: "production-db-daily",
      volumeId: "vol-001",
      volumeName: "production-db",
      size: 342,
      created: "2024-12-20 02:00",
      status: "completed",
      type: "automated",
    },
    {
      id: "snap-002",
      name: "app-storage-backup",
      volumeId: "vol-002",
      volumeName: "app-storage",
      size: 187,
      created: "2024-12-19 14:30",
      status: "completed",
      type: "manual",
    },
    {
      id: "snap-003",
      name: "pre-migration",
      volumeId: "vol-001",
      volumeName: "production-db",
      size: 340,
      created: "2024-12-18 09:15",
      status: "completed",
      type: "manual",
    },
  ];

  const files = [
    {
      id: 1,
      name: "customer-data.db",
      type: "database",
      size: 2500000000,
      modified: "2024-12-20 14:30",
      owner: "system",
      shared: false,
      starred: true,
    },
    {
      id: 2,
      name: "application-logs",
      type: "folder",
      items: 1247,
      modified: "2024-12-20 12:15",
      owner: "admin",
      shared: true,
      starred: false,
    },
    {
      id: 3,
      name: "backup-2024-12.tar.gz",
      type: "archive",
      size: 15000000000,
      modified: "2024-12-19 02:00",
      owner: "system",
      shared: false,
      starred: false,
    },
    {
      id: 4,
      name: "deployment-config.yaml",
      type: "code",
      size: 45000,
      modified: "2024-12-18 16:45",
      owner: "admin",
      shared: true,
      starred: true,
    },
    {
      id: 5,
      name: "media-assets",
      type: "folder",
      items: 523,
      modified: "2024-12-17 10:20",
      owner: "admin",
      shared: false,
      starred: false,
    },
    {
      id: 6,
      name: "prometheus-metrics.json",
      type: "file",
      size: 8500000,
      modified: "2024-12-20 15:00",
      owner: "system",
      shared: false,
      starred: false,
    },
  ];

  const backups = [
    {
      id: "bak-001",
      name: "Full System Backup",
      type: "full",
      size: 2400,
      created: "2024-12-20 02:00",
      status: "completed",
      retention: "30 days",
      location: "Oracle Cloud",
    },
    {
      id: "bak-002",
      name: "Database Backup",
      type: "incremental",
      size: 340,
      created: "2024-12-19 14:00",
      status: "completed",
      retention: "90 days",
      location: "Local ZFS",
    },
    {
      id: "bak-003",
      name: "Application Data",
      type: "differential",
      size: 187,
      created: "2024-12-18 08:30",
      status: "completed",
      retention: "60 days",
      location: "Oracle Cloud",
    },
  ];

  const formatBytes = (bytes) => {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
  };

  const getFileIcon = (type) => {
    switch (type) {
      case "folder":
        return FolderOpen;
      case "database":
        return Database;
      case "code":
        return FileCode;
      case "image":
        return FileImage;
      case "video":
        return FileVideo;
      case "audio":
        return FileAudio;
      case "archive":
        return Archive;
      default:
        return File;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case "attached":
        return "bg-green-500/20 text-green-400 border-green-500/30";
      case "detached":
        return "bg-slate-500/20 text-slate-400 border-slate-500/30";
      case "creating":
        return "bg-blue-500/20 text-blue-400 border-blue-500/30";
      case "error":
        return "bg-red-500/20 text-red-400 border-red-500/30";
      case "completed":
        return "bg-green-500/20 text-green-400 border-green-500/30";
      case "failed":
        return "bg-red-500/20 text-red-400 border-red-500/30";
      default:
        return "bg-slate-500/20 text-slate-400 border-slate-500/30";
    }
  };

  const usagePercent = (storageStats.used / storageStats.totalCapacity) * 100;

  return (
    <div className="min-h-screen bg-slate-950 text-white p-6">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold mb-2">Storage Management</h1>
            <p className="text-slate-400">
              Manage volumes, snapshots, backups, and files
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all flex items-center space-x-2">
              <RefreshCw className="w-4 h-4" />
              <span>Sync</span>
            </button>
            <button
              onClick={() => setShowVolumeModal(true)}
              className="px-4 py-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 rounded-lg font-semibold transition-all flex items-center space-x-2"
            >
              <Plus className="w-4 h-4" />
              <span>Create Volume</span>
            </button>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="flex space-x-2 border-b border-slate-800">
          {["overview", "volumes", "snapshots", "backups", "files"].map(
            (view) => (
              <button
                key={view}
                onClick={() => setActiveView(view)}
                className={`px-4 py-3 font-medium capitalize transition-all ${
                  activeView === view
                    ? "border-b-2 border-blue-500 text-white"
                    : "text-slate-400 hover:text-white"
                }`}
              >
                {view}
              </button>
            ),
          )}
        </div>
      </div>

      {/* Overview View */}
      {activeView === "overview" && (
        <div className="space-y-6">
          {/* Stats Grid */}
          <div className="grid grid-cols-6 gap-6">
            <div className="col-span-2 bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center">
                  <HardDrive className="w-6 h-6 text-blue-400" />
                </div>
                <TrendingUp className="w-5 h-5 text-green-400" />
              </div>
              <div className="mb-4">
                <div className="text-3xl font-bold text-white mb-1">
                  {storageStats.used} GB
                </div>
                <div className="text-sm text-slate-400">
                  Used of {storageStats.totalCapacity} GB
                </div>
              </div>
              <div className="mb-2">
                <div className="w-full bg-slate-700 rounded-full h-3 overflow-hidden">
                  <div
                    className="bg-gradient-to-r from-blue-500 to-purple-600 h-3 rounded-full transition-all"
                    style={{ width: `${usagePercent}%` }}
                  ></div>
                </div>
              </div>
              <div className="flex items-center justify-between text-xs text-slate-400">
                <span>{usagePercent.toFixed(1)}% used</span>
                <span>{storageStats.available} GB available</span>
              </div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center">
                  <Database className="w-6 h-6 text-purple-400" />
                </div>
                <Activity className="w-5 h-5 text-purple-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">
                {storageStats.volumes}
              </div>
              <div className="text-sm text-slate-400">Total Volumes</div>
              <div className="mt-3 text-xs text-green-400">+2 this week</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center">
                  <GitBranch className="w-6 h-6 text-green-400" />
                </div>
                <Activity className="w-5 h-5 text-green-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">
                {storageStats.snapshots}
              </div>
              <div className="text-sm text-slate-400">Snapshots</div>
              <div className="mt-3 text-xs text-blue-400">12 automated</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-orange-500/20 rounded-lg flex items-center justify-center">
                  <Package className="w-6 h-6 text-orange-400" />
                </div>
                <CheckCircle className="w-5 h-5 text-green-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">
                {storageStats.backups}
              </div>
              <div className="text-sm text-slate-400">Active Backups</div>
              <div className="mt-3 text-xs text-green-400">Last: 2h ago</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-cyan-500/20 rounded-lg flex items-center justify-center">
                  <Zap className="w-6 h-6 text-cyan-400" />
                </div>
                <BarChart3 className="w-5 h-5 text-cyan-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">3000</div>
              <div className="text-sm text-slate-400">Avg IOPS</div>
              <div className="mt-3 text-xs text-cyan-400">250 MB/s</div>
            </div>
          </div>

          {/* Storage Distribution */}
          <div className="grid grid-cols-2 gap-6">
            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <h2 className="text-xl font-bold mb-6">Storage by Type</h2>
              <div className="space-y-4">
                {[
                  {
                    type: "NVMe SSD",
                    used: 574,
                    total: 850,
                    color: "blue",
                    iops: "3000",
                  },
                  {
                    type: "HDD",
                    used: 823,
                    total: 1000,
                    color: "green",
                    iops: "500",
                  },
                  {
                    type: "Object Storage",
                    used: 450,
                    total: 2246,
                    color: "purple",
                    iops: "N/A",
                  },
                ].map((storage, idx) => (
                  <div key={idx} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-300 font-medium">
                        {storage.type}
                      </span>
                      <div className="flex items-center space-x-3">
                        <span className="text-xs text-slate-400">
                          {storage.iops} IOPS
                        </span>
                        <span className="font-semibold text-white">
                          {storage.used} / {storage.total} GB
                        </span>
                      </div>
                    </div>
                    <div className="relative w-full h-2 bg-slate-800 rounded-full overflow-hidden">
                      <div
                        className={`absolute left-0 top-0 h-full bg-gradient-to-r from-${storage.color}-500 to-${storage.color}-600 transition-all`}
                        style={{
                          width: `${(storage.used / storage.total) * 100}%`,
                        }}
                      ></div>
                    </div>
                    <div className="flex items-center justify-between text-xs text-slate-500">
                      <span>
                        {((storage.used / storage.total) * 100).toFixed(1)}%
                        used
                      </span>
                      <span>{storage.total - storage.used} GB free</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <h2 className="text-xl font-bold mb-6">Recent Activity</h2>
              <div className="space-y-3">
                {[
                  {
                    action: "Snapshot created",
                    target: "production-db",
                    time: "5m ago",
                    status: "success",
                  },
                  {
                    action: "Volume attached",
                    target: "vm-app-01",
                    time: "1h ago",
                    status: "success",
                  },
                  {
                    action: "Backup completed",
                    target: "Full System",
                    time: "2h ago",
                    status: "success",
                  },
                  {
                    action: "Volume resized",
                    target: "dev-workspace",
                    time: "3h ago",
                    status: "success",
                  },
                  {
                    action: "Snapshot failed",
                    target: "backup-volume",
                    time: "5h ago",
                    status: "error",
                  },
                  {
                    action: "Volume created",
                    target: "test-storage",
                    time: "1d ago",
                    status: "success",
                  },
                ].map((activity, idx) => (
                  <div
                    key={idx}
                    className="flex items-center space-x-3 p-3 bg-slate-800/30 rounded-lg hover:bg-slate-800/50 transition-all"
                  >
                    <div
                      className={`w-2 h-2 rounded-full ${activity.status === "success" ? "bg-green-400" : "bg-red-400"}`}
                    ></div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-white">
                        {activity.action}
                      </p>
                      <p className="text-xs text-slate-400">
                        {activity.target}
                      </p>
                    </div>
                    <span className="text-xs text-slate-500">
                      {activity.time}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="grid grid-cols-4 gap-4">
            {[
              { label: "Create Volume", icon: Plus, color: "blue" },
              { label: "Take Snapshot", icon: GitBranch, color: "green" },
              { label: "Run Backup", icon: Package, color: "orange" },
              { label: "Restore Data", icon: RefreshCw, color: "purple" },
            ].map((action, idx) => (
              <button
                key={idx}
                className={`bg-${action.color}-500/10 border border-${action.color}-500/30 hover:bg-${action.color}-500/20 rounded-xl p-6 transition-all group`}
              >
                <action.icon
                  className={`w-8 h-8 text-${action.color}-400 mx-auto mb-3 group-hover:scale-110 transition-transform`}
                />
                <div className="text-sm font-semibold text-white">
                  {action.label}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Volumes View */}
      {activeView === "volumes" && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search volumes..."
                  className="bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Types</option>
                <option>NVMe SSD</option>
                <option>HDD</option>
              </select>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Status</option>
                <option>Attached</option>
                <option>Detached</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {volumes.map((volume) => (
              <div
                key={volume.id}
                className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6 hover:border-blue-500/50 transition-all"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center">
                      <Database className="w-6 h-6 text-blue-400" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-white">
                        {volume.name}
                      </h3>
                      <p className="text-xs text-slate-400">{volume.id}</p>
                    </div>
                  </div>
                  <span
                    className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold border ${getStatusColor(volume.status)}`}
                  >
                    {volume.status}
                  </span>
                </div>

                <div className="space-y-3 mb-4">
                  <div>
                    <div className="flex items-center justify-between text-sm mb-2">
                      <span className="text-slate-400">Storage Used</span>
                      <span className="font-semibold text-white">
                        {volume.used} / {volume.size} GB
                      </span>
                    </div>
                    <div className="w-full bg-slate-700 rounded-full h-2 overflow-hidden">
                      <div
                        className="bg-gradient-to-r from-blue-500 to-purple-600 h-2 rounded-full transition-all"
                        style={{
                          width: `${(volume.used / volume.size) * 100}%`,
                        }}
                      ></div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <span className="text-slate-400 block mb-1">Type</span>
                      <span className="text-white font-medium">
                        {volume.type}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 block mb-1">IOPS</span>
                      <span className="text-white font-medium">
                        {volume.iops}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 block mb-1">
                        Throughput
                      </span>
                      <span className="text-white font-medium">
                        {volume.throughput}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 block mb-1">
                        Snapshots
                      </span>
                      <span className="text-white font-medium">
                        {volume.snapshots}
                      </span>
                    </div>
                  </div>

                  {volume.attachedTo && (
                    <div className="bg-slate-800/50 rounded-lg p-3 flex items-center space-x-2">
                      <Server className="w-4 h-4 text-green-400" />
                      <span className="text-sm text-slate-300">
                        Attached to:{" "}
                      </span>
                      <span className="text-sm font-semibold text-white">
                        {volume.attachedTo}
                      </span>
                    </div>
                  )}
                </div>

                <div className="flex space-x-2">
                  <button className="flex-1 px-3 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-semibold transition-all">
                    Manage
                  </button>
                  <button className="px-3 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-all">
                    <GitBranch className="w-4 h-4" />
                  </button>
                  <button className="px-3 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-all">
                    <MoreVertical className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Snapshots View */}
      {activeView === "snapshots" && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search snapshots..."
                  className="bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Volumes</option>
                {volumes.map((v) => (
                  <option key={v.id}>{v.name}</option>
                ))}
              </select>
            </div>
            <button className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg font-semibold transition-all flex items-center space-x-2">
              <GitBranch className="w-4 h-4" />
              <span>Create Snapshot</span>
            </button>
          </div>

          <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl overflow-hidden">
            <table className="w-full">
              <thead className="bg-slate-900">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Snapshot
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Source Volume
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Size
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Created
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Type
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Status
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {snapshots.map((snap) => (
                  <tr
                    key={snap.id}
                    className="hover:bg-slate-800/30 transition-colors"
                  >
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center">
                          <GitBranch className="w-5 h-5 text-green-400" />
                        </div>
                        <div>
                          <div className="font-semibold text-white">
                            {snap.name}
                          </div>
                          <div className="text-xs text-slate-400">
                            {snap.id}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-300">
                      {snap.volumeName}
                    </td>
                    <td className="px-6 py-4 text-sm font-semibold text-white">
                      {snap.size} GB
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-300">
                      {snap.created}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold ${
                          snap.type === "automated"
                            ? "bg-blue-500/20 text-blue-400 border border-blue-500/30"
                            : "bg-purple-500/20 text-purple-400 border border-purple-500/30"
                        }`}
                      >
                        {snap.type}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${getStatusColor(snap.status)}`}
                      >
                        {snap.status}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-2">
                        <button
                          className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                          title="Restore"
                        >
                          <RefreshCw className="w-4 h-4" />
                        </button>
                        <button
                          className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                          title="Create Volume"
                        >
                          <Copy className="w-4 h-4" />
                        </button>
                        <button
                          className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                          title="Delete"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                        <button
                          className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                          title="More"
                        >
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Backups View */}
      {activeView === "backups" && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search backups..."
                  className="bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Types</option>
                <option>Full</option>
                <option>Incremental</option>
                <option>Differential</option>
              </select>
            </div>
            <button className="px-4 py-2 bg-orange-600 hover:bg-orange-700 rounded-lg font-semibold transition-all flex items-center space-x-2">
              <Package className="w-4 h-4" />
              <span>Run Backup</span>
            </button>
          </div>

          <div className="grid grid-cols-1 gap-6">
            {backups.map((backup) => (
              <div
                key={backup.id}
                className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6 hover:border-orange-500/50 transition-all"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4 flex-1">
                    <div className="w-16 h-16 bg-orange-500/20 rounded-lg flex items-center justify-center">
                      <Package className="w-8 h-8 text-orange-400" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <h3 className="text-lg font-semibold text-white">
                          {backup.name}
                        </h3>
                        <span
                          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold border ${getStatusColor(backup.status)}`}
                        >
                          {backup.status}
                        </span>
                        <span
                          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold ${
                            backup.type === "full"
                              ? "bg-orange-500/20 text-orange-400 border border-orange-500/30"
                              : backup.type === "incremental"
                                ? "bg-blue-500/20 text-blue-400 border border-blue-500/30"
                                : "bg-purple-500/20 text-purple-400 border border-purple-500/30"
                          }`}
                        >
                          {backup.type}
                        </span>
                      </div>
                      <div className="flex items-center space-x-6 text-sm text-slate-400">
                        <div className="flex items-center space-x-2">
                          <HardDrive className="w-4 h-4" />
                          <span>{backup.size} GB</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Clock className="w-4 h-4" />
                          <span>{backup.created}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Globe className="w-4 h-4" />
                          <span>{backup.location}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Calendar className="w-4 h-4" />
                          <span>Retention: {backup.retention}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-semibold transition-all flex items-center space-x-2">
                      <RefreshCw className="w-4 h-4" />
                      <span>Restore</span>
                    </button>
                    <button className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-all">
                      <Download className="w-4 h-4" />
                    </button>
                    <button className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-all">
                      <MoreVertical className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Backup Schedule */}
          <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
            <h2 className="text-xl font-bold mb-6">Backup Schedule</h2>
            <div className="space-y-4">
              {[
                {
                  name: "Daily Full Backup",
                  schedule: "Every day at 2:00 AM",
                  enabled: true,
                  next: "2024-12-21 02:00",
                },
                {
                  name: "Hourly Incremental",
                  schedule: "Every hour",
                  enabled: true,
                  next: "2024-12-20 17:00",
                },
                {
                  name: "Weekly Archive",
                  schedule: "Every Sunday at 1:00 AM",
                  enabled: true,
                  next: "2024-12-22 01:00",
                },
                {
                  name: "Monthly Offsite",
                  schedule: "1st of each month",
                  enabled: false,
                  next: "2025-01-01 00:00",
                },
              ].map((schedule, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg hover:bg-slate-800/50 transition-all"
                >
                  <div className="flex items-center space-x-4">
                    <div
                      className={`w-3 h-3 rounded-full ${schedule.enabled ? "bg-green-400" : "bg-slate-600"}`}
                    ></div>
                    <div>
                      <h4 className="font-semibold text-white">
                        {schedule.name}
                      </h4>
                      <p className="text-sm text-slate-400">
                        {schedule.schedule}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-4">
                    <div className="text-right">
                      <p className="text-xs text-slate-400">Next run</p>
                      <p className="text-sm text-white font-medium">
                        {schedule.next}
                      </p>
                    </div>
                    <button className="p-2 hover:bg-slate-700 rounded-lg transition-colors">
                      <Edit3 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Files View */}
      {activeView === "files" && (
        <div className="space-y-6">
          {/* File Browser Header */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search files and folders..."
                  className="bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-96"
                />
              </div>
              <button className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-all">
                <Filter className="w-4 h-4" />
              </button>
              <div className="flex bg-slate-800 rounded-lg">
                <button
                  onClick={() => setViewMode("grid")}
                  className={`p-2 rounded-lg transition-all ${viewMode === "grid" ? "bg-blue-600" : "hover:bg-slate-700"}`}
                >
                  <Grid className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setViewMode("list")}
                  className={`p-2 rounded-lg transition-all ${viewMode === "list" ? "bg-blue-600" : "hover:bg-slate-700"}`}
                >
                  <List className="w-4 h-4" />
                </button>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setShowUploadModal(true)}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg font-semibold transition-all flex items-center space-x-2"
              >
                <Upload className="w-4 h-4" />
                <span>Upload</span>
              </button>
              <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all flex items-center space-x-2">
                <Folder className="w-4 h-4" />
                <span>New Folder</span>
              </button>
            </div>
          </div>

          {/* Breadcrumb */}
          <div className="flex items-center space-x-2 text-sm">
            {currentPath.map((path, idx) => (
              <div key={idx} className="flex items-center space-x-2">
                {idx > 0 && <ChevronRight className="w-4 h-4 text-slate-500" />}
                <button className="text-slate-400 hover:text-white transition-colors capitalize">
                  {path}
                </button>
              </div>
            ))}
          </div>

          {/* File Grid/List */}
          {viewMode === "grid" ? (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
              {files.map((file) => {
                const Icon = getFileIcon(file.type);
                return (
                  <div
                    key={file.id}
                    className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-4 hover:border-blue-500/50 transition-all cursor-pointer group"
                  >
                    <div className="flex items-start justify-between mb-3">
                      <div
                        className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                          file.type === "folder"
                            ? "bg-blue-500/20"
                            : file.type === "database"
                              ? "bg-green-500/20"
                              : file.type === "code"
                                ? "bg-purple-500/20"
                                : file.type === "archive"
                                  ? "bg-orange-500/20"
                                  : "bg-slate-700"
                        }`}
                      >
                        <Icon
                          className={`w-6 h-6 ${
                            file.type === "folder"
                              ? "text-blue-400"
                              : file.type === "database"
                                ? "text-green-400"
                                : file.type === "code"
                                  ? "text-purple-400"
                                  : file.type === "archive"
                                    ? "text-orange-400"
                                    : "text-slate-400"
                          }`}
                        />
                      </div>
                      <div className="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        {file.starred && (
                          <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                        )}
                        {file.shared && (
                          <Users className="w-4 h-4 text-blue-400" />
                        )}
                      </div>
                    </div>
                    <h3 className="font-semibold text-white text-sm mb-1 truncate">
                      {file.name}
                    </h3>
                    <p className="text-xs text-slate-400">
                      {file.type === "folder"
                        ? `${file.items} items`
                        : formatBytes(file.size)}
                    </p>
                    <div className="mt-3 pt-3 border-t border-slate-800 flex items-center justify-between">
                      <span className="text-xs text-slate-500">
                        {file.modified.split(" ")[0]}
                      </span>
                      <button className="p-1 hover:bg-slate-700 rounded opacity-0 group-hover:opacity-100 transition-opacity">
                        <MoreVertical className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl overflow-hidden">
              <table className="w-full">
                <thead className="bg-slate-900">
                  <tr>
                    <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                      Name
                    </th>
                    <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                      Owner
                    </th>
                    <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                      Modified
                    </th>
                    <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                      Size
                    </th>
                    <th className="px-6 py-4 text-left text-xs font-semibold text-slate-400 uppercase">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {files.map((file) => {
                    const Icon = getFileIcon(file.type);
                    return (
                      <tr
                        key={file.id}
                        className="hover:bg-slate-800/30 transition-colors"
                      >
                        <td className="px-6 py-4">
                          <div className="flex items-center space-x-3">
                            <Icon
                              className={`w-5 h-5 ${
                                file.type === "folder"
                                  ? "text-blue-400"
                                  : file.type === "database"
                                    ? "text-green-400"
                                    : file.type === "code"
                                      ? "text-purple-400"
                                      : file.type === "archive"
                                        ? "text-orange-400"
                                        : "text-slate-400"
                              }`}
                            />
                            <div className="flex items-center space-x-2">
                              <span className="font-medium text-white">
                                {file.name}
                              </span>
                              {file.starred && (
                                <Star className="w-3 h-3 text-yellow-400 fill-yellow-400" />
                              )}
                              {file.shared && (
                                <Users className="w-3 h-3 text-blue-400" />
                              )}
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          {file.owner}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          {file.modified}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          {file.type === "folder"
                            ? `${file.items} items`
                            : formatBytes(file.size)}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center space-x-2">
                            <button
                              className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                              title="Download"
                            >
                              <Download className="w-4 h-4" />
                            </button>
                            <button
                              className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                              title="Share"
                            >
                              <Share2 className="w-4 h-4" />
                            </button>
                            <button
                              className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
                              title="More"
                            >
                              <MoreVertical className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Create Volume Modal */}
      {showVolumeModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-6">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Create New Volume</h2>
              <button
                onClick={() => setShowVolumeModal(false)}
                className="p-2 hover:bg-slate-800 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Volume Name
                </label>
                <input
                  type="text"
                  placeholder="my-volume"
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Size (GB)
                  </label>
                  <input
                    type="number"
                    placeholder="100"
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Type
                  </label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>NVMe SSD</option>
                    <option>SSD</option>
                    <option>HDD</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    IOPS
                  </label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>3000 (Standard)</option>
                    <option>5000 (High Performance)</option>
                    <option>10000 (Ultra Performance)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Attach to VM
                  </label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>None (Detached)</option>
                    <option>vm-prod-01</option>
                    <option>vm-app-01</option>
                    <option>vm-dev-01</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="encryption"
                  className="w-4 h-4 rounded border-slate-700 bg-slate-800 text-blue-600"
                />
                <label htmlFor="encryption" className="text-sm text-slate-300">
                  Enable encryption at rest
                </label>
              </div>

              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="auto-snapshot"
                  className="w-4 h-4 rounded border-slate-700 bg-slate-800 text-blue-600"
                />
                <label
                  htmlFor="auto-snapshot"
                  className="text-sm text-slate-300"
                >
                  Enable automatic daily snapshots
                </label>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  onClick={() => setShowVolumeModal(false)}
                  className="flex-1 px-6 py-3 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all"
                >
                  Cancel
                </button>
                <button className="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 rounded-lg font-semibold transition-all">
                  Create Volume
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Upload Modal */}
      {showUploadModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-6">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Upload Files</h2>
              <button
                onClick={() => setShowUploadModal(false)}
                className="p-2 hover:bg-slate-800 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="border-2 border-dashed border-slate-700 rounded-xl p-12 text-center hover:border-blue-500 transition-all cursor-pointer">
              <Upload className="w-16 h-16 text-slate-500 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-white mb-2">
                Drop files here or click to browse
              </h3>
              <p className="text-sm text-slate-400">
                Support for all file types up to 5GB per file
              </p>
            </div>

            <div className="mt-6 space-y-3">
              <div className="text-sm font-medium text-slate-300 mb-3">
                Upload Queue
              </div>
              {/* Upload queue items would go here */}
              <div className="text-center py-8 text-slate-500">
                No files selected
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
