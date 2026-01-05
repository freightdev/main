import {
  Activity,
  AlertCircle,
  AlertTriangle,
  BarChart3,
  Bell,
  CheckCircle,
  Clock,
  Cpu,
  Download,
  Gauge,
  HardDrive,
  Info,
  Mail,
  MessageSquare,
  MoreVertical,
  Network,
  Pause,
  Phone,
  Play,
  Search,
  Server,
  Settings,
  TrendingUp,
  Webhook,
  Zap,
} from "lucide-react";
import { useEffect, useState } from "react";

export default function CloudDashMonitoring() {
  const [activeView, setActiveView] = useState("dashboard");
  const [timeRange, setTimeRange] = useState("1h");
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [showAlertModal, setShowAlertModal] = useState(false);
  const [selectedAlert, setSelectedAlert] = useState(null);

  // Simulated real-time metrics
  const [metrics, setMetrics] = useState({
    cpu: 45,
    memory: 62,
    disk: 38,
    network: 1250,
    latency: 45,
    uptime: 99.97,
  });

  useEffect(() => {
    if (autoRefresh) {
      const interval = setInterval(() => {
        setMetrics((prev) => ({
          cpu: Math.max(
            10,
            Math.min(95, prev.cpu + (Math.random() - 0.5) * 10),
          ),
          memory: Math.max(
            20,
            Math.min(90, prev.memory + (Math.random() - 0.5) * 5),
          ),
          disk: Math.max(
            20,
            Math.min(80, prev.disk + (Math.random() - 0.5) * 2),
          ),
          network: Math.max(
            500,
            Math.min(3000, prev.network + (Math.random() - 0.5) * 200),
          ),
          latency: Math.max(
            20,
            Math.min(100, prev.latency + (Math.random() - 0.5) * 10),
          ),
          uptime: 99.97,
        }));
      }, 3000);
      return () => clearInterval(interval);
    }
  }, [autoRefresh]);

  const alerts = [
    {
      id: 1,
      severity: "critical",
      title: "High CPU Usage on L4-Dell",
      description: "CPU utilization has exceeded 85% for 15 minutes",
      host: "L4-Dell",
      metric: "CPU",
      value: "89%",
      threshold: "85%",
      time: "2m ago",
      status: "firing",
      acknowledged: false,
    },
    {
      id: 2,
      severity: "warning",
      title: "Memory Usage High on L2-Yoga",
      description: "Memory utilization at 78%",
      host: "L2-Yoga",
      metric: "Memory",
      value: "78%",
      threshold: "75%",
      time: "15m ago",
      status: "firing",
      acknowledged: false,
    },
    {
      id: 3,
      severity: "info",
      title: "Disk Space Low on vol-backup",
      description: "Disk usage is at 82%",
      host: "vol-backup",
      metric: "Disk",
      value: "82%",
      threshold: "80%",
      time: "1h ago",
      status: "firing",
      acknowledged: true,
    },
    {
      id: 4,
      severity: "critical",
      title: "Service Down: nomad-client",
      description: "Nomad client on L3-TUF is not responding",
      host: "L3-TUF",
      metric: "Service Health",
      value: "Down",
      threshold: "Up",
      time: "5m ago",
      status: "firing",
      acknowledged: false,
    },
    {
      id: 5,
      severity: "warning",
      title: "High Network Latency",
      description: "Average latency increased to 145ms",
      host: "Network",
      metric: "Latency",
      value: "145ms",
      threshold: "100ms",
      time: "30m ago",
      status: "resolved",
      acknowledged: true,
    },
  ];

  const hosts = [
    {
      id: "l1",
      name: "L1-Vivobook",
      status: "healthy",
      cpu: 45,
      memory: 62,
      disk: 38,
      uptime: "15d 3h",
      alerts: 0,
    },
    {
      id: "l2",
      name: "L2-Yoga",
      status: "warning",
      cpu: 67,
      memory: 78,
      disk: 42,
      uptime: "12d 18h",
      alerts: 1,
    },
    {
      id: "l3",
      name: "L3-TUF",
      status: "critical",
      cpu: 23,
      memory: 45,
      disk: 31,
      uptime: "8d 12h",
      alerts: 1,
    },
    {
      id: "l4",
      name: "L4-Dell",
      status: "critical",
      cpu: 89,
      memory: 71,
      disk: 55,
      uptime: "6d 4h",
      alerts: 1,
    },
  ];

  const services = [
    {
      name: "Nomad Server",
      status: "healthy",
      uptime: "99.99%",
      latency: "12ms",
    },
    {
      name: "Consul Cluster",
      status: "healthy",
      uptime: "99.98%",
      latency: "8ms",
    },
    {
      name: "Traefik Ingress",
      status: "healthy",
      uptime: "99.97%",
      latency: "25ms",
    },
    {
      name: "Prometheus",
      status: "healthy",
      uptime: "99.95%",
      latency: "45ms",
    },
    { name: "Grafana", status: "healthy", uptime: "99.96%", latency: "35ms" },
    {
      name: "Nomad Client (L3)",
      status: "down",
      uptime: "98.45%",
      latency: "N/A",
    },
  ];

  const alertRules = [
    {
      id: 1,
      name: "CPU Threshold",
      condition: "cpu > 85% for 10m",
      severity: "critical",
      enabled: true,
      notifications: ["email", "slack"],
    },
    {
      id: 2,
      name: "Memory Alert",
      condition: "memory > 75% for 5m",
      severity: "warning",
      enabled: true,
      notifications: ["email"],
    },
    {
      id: 3,
      name: "Disk Space",
      condition: "disk > 80%",
      severity: "warning",
      enabled: true,
      notifications: ["email", "webhook"],
    },
    {
      id: 4,
      name: "Service Health",
      condition: "service_status == down",
      severity: "critical",
      enabled: true,
      notifications: ["email", "slack", "sms"],
    },
    {
      id: 5,
      name: "Network Latency",
      condition: "latency > 100ms for 15m",
      severity: "warning",
      enabled: false,
      notifications: ["email"],
    },
  ];

  const getSeverityColor = (severity) => {
    switch (severity) {
      case "critical":
        return "bg-red-500/20 text-red-400 border-red-500/30";
      case "warning":
        return "bg-yellow-500/20 text-yellow-400 border-yellow-500/30";
      case "info":
        return "bg-blue-500/20 text-blue-400 border-blue-500/30";
      default:
        return "bg-slate-500/20 text-slate-400 border-slate-500/30";
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case "healthy":
        return "text-green-400";
      case "warning":
        return "text-yellow-400";
      case "critical":
        return "text-red-400";
      case "down":
        return "text-red-400";
      default:
        return "text-slate-400";
    }
  };

  const getMetricColor = (value, threshold) => {
    if (value >= 85) return "text-red-400";
    if (value >= 75) return "text-yellow-400";
    return "text-green-400";
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white p-6">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold mb-2">Monitoring & Alerts</h1>
            <p className="text-slate-400">
              Real-time infrastructure monitoring and alerting
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`px-4 py-2 rounded-lg font-semibold transition-all flex items-center space-x-2 ${
                autoRefresh
                  ? "bg-green-600 hover:bg-green-700"
                  : "bg-slate-800 hover:bg-slate-700"
              }`}
            >
              {autoRefresh ? (
                <Play className="w-4 h-4" />
              ) : (
                <Pause className="w-4 h-4" />
              )}
              <span>{autoRefresh ? "Live" : "Paused"}</span>
            </button>
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm"
            >
              <option value="5m">Last 5 minutes</option>
              <option value="15m">Last 15 minutes</option>
              <option value="1h">Last hour</option>
              <option value="6h">Last 6 hours</option>
              <option value="24h">Last 24 hours</option>
              <option value="7d">Last 7 days</option>
            </select>
            <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all flex items-center space-x-2">
              <Download className="w-4 h-4" />
              <span>Export</span>
            </button>
            <button
              onClick={() => setShowAlertModal(true)}
              className="px-4 py-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 rounded-lg font-semibold transition-all flex items-center space-x-2"
            >
              <Bell className="w-4 h-4" />
              <span>Create Alert</span>
            </button>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="flex space-x-2 border-b border-slate-800">
          {["dashboard", "alerts", "metrics", "hosts", "services", "logs"].map(
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

      {/* Dashboard View */}
      {activeView === "dashboard" && (
        <div className="space-y-6">
          {/* Top Stats */}
          <div className="grid grid-cols-6 gap-6">
            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center">
                  <CheckCircle className="w-6 h-6 text-green-400" />
                </div>
                <TrendingUp className="w-5 h-5 text-green-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">
                {metrics.uptime}%
              </div>
              <div className="text-sm text-slate-400">System Uptime</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center">
                  <Cpu className="w-6 h-6 text-blue-400" />
                </div>
                <Activity className="w-5 h-5 text-blue-400 animate-pulse" />
              </div>
              <div
                className={`text-3xl font-bold mb-1 ${getMetricColor(metrics.cpu, 75)}`}
              >
                {Math.round(metrics.cpu)}%
              </div>
              <div className="text-sm text-slate-400">Avg CPU Usage</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center">
                  <Server className="w-6 h-6 text-purple-400" />
                </div>
                <Activity className="w-5 h-5 text-purple-400 animate-pulse" />
              </div>
              <div
                className={`text-3xl font-bold mb-1 ${getMetricColor(metrics.memory, 75)}`}
              >
                {Math.round(metrics.memory)}%
              </div>
              <div className="text-sm text-slate-400">Memory Usage</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-orange-500/20 rounded-lg flex items-center justify-center">
                  <HardDrive className="w-6 h-6 text-orange-400" />
                </div>
                <BarChart3 className="w-5 h-5 text-orange-400" />
              </div>
              <div
                className={`text-3xl font-bold mb-1 ${getMetricColor(metrics.disk, 75)}`}
              >
                {Math.round(metrics.disk)}%
              </div>
              <div className="text-sm text-slate-400">Disk Usage</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-cyan-500/20 rounded-lg flex items-center justify-center">
                  <Network className="w-6 h-6 text-cyan-400" />
                </div>
                <Zap className="w-5 h-5 text-cyan-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">
                {Math.round(metrics.network)}
              </div>
              <div className="text-sm text-slate-400">Mbps Network</div>
            </div>

            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center">
                  <Gauge className="w-6 h-6 text-green-400" />
                </div>
                <Clock className="w-5 h-5 text-green-400" />
              </div>
              <div className="text-3xl font-bold text-white mb-1">
                {Math.round(metrics.latency)}ms
              </div>
              <div className="text-sm text-slate-400">Avg Latency</div>
            </div>
          </div>

          {/* Active Alerts Banner */}
          {alerts.filter((a) => a.status === "firing" && !a.acknowledged)
            .length > 0 && (
            <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 bg-red-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                  <AlertTriangle className="w-6 h-6 text-red-400 animate-pulse" />
                </div>
                <div className="flex-1">
                  <h3 className="text-lg font-bold text-red-400 mb-2">
                    {
                      alerts.filter(
                        (a) => a.status === "firing" && !a.acknowledged,
                      ).length
                    }{" "}
                    Active Alerts Require Attention
                  </h3>
                  <div className="grid grid-cols-2 gap-3">
                    {alerts
                      .filter((a) => a.status === "firing" && !a.acknowledged)
                      .slice(0, 4)
                      .map((alert) => (
                        <div
                          key={alert.id}
                          className="bg-slate-900/50 rounded-lg p-3 flex items-center justify-between"
                        >
                          <div className="flex-1">
                            <p className="text-sm font-semibold text-white mb-1">
                              {alert.title}
                            </p>
                            <p className="text-xs text-slate-400">
                              {alert.host} • {alert.time}
                            </p>
                          </div>
                          <button
                            onClick={() => setSelectedAlert(alert)}
                            className="ml-3 px-3 py-1 bg-red-600 hover:bg-red-700 rounded text-xs font-semibold transition-all"
                          >
                            View
                          </button>
                        </div>
                      ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Charts Grid */}
          <div className="grid grid-cols-2 gap-6">
            {/* CPU Chart */}
            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold">CPU Usage</h2>
                <div className="flex items-center space-x-2">
                  <span
                    className={`text-2xl font-bold ${getMetricColor(metrics.cpu, 75)}`}
                  >
                    {Math.round(metrics.cpu)}%
                  </span>
                </div>
              </div>
              <div className="h-64 flex items-end space-x-2">
                {Array.from({ length: 20 }, (_, i) => {
                  const height = 30 + Math.random() * 70;
                  const isHigh = height > 75;
                  return (
                    <div key={i} className="flex-1 flex flex-col justify-end">
                      <div
                        className={`w-full rounded-t transition-all ${
                          isHigh
                            ? "bg-gradient-to-t from-red-500 to-orange-500"
                            : "bg-gradient-to-t from-blue-500 to-cyan-500"
                        }`}
                        style={{ height: `${height}%` }}
                      ></div>
                    </div>
                  );
                })}
              </div>
              <div className="mt-4 flex items-center justify-between text-xs text-slate-500">
                <span>{timeRange === "1h" ? "60m ago" : "24h ago"}</span>
                <span>Now</span>
              </div>
            </div>

            {/* Memory Chart */}
            <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold">Memory Usage</h2>
                <div className="flex items-center space-x-2">
                  <span
                    className={`text-2xl font-bold ${getMetricColor(metrics.memory, 75)}`}
                  >
                    {Math.round(metrics.memory)}%
                  </span>
                </div>
              </div>
              <div className="h-64 flex items-end space-x-2">
                {Array.from({ length: 20 }, (_, i) => {
                  const height = 40 + Math.random() * 50;
                  const isHigh = height > 75;
                  return (
                    <div key={i} className="flex-1 flex flex-col justify-end">
                      <div
                        className={`w-full rounded-t transition-all ${
                          isHigh
                            ? "bg-gradient-to-t from-yellow-500 to-orange-500"
                            : "bg-gradient-to-t from-purple-500 to-pink-500"
                        }`}
                        style={{ height: `${height}%` }}
                      ></div>
                    </div>
                  );
                })}
              </div>
              <div className="mt-4 flex items-center justify-between text-xs text-slate-500">
                <span>{timeRange === "1h" ? "60m ago" : "24h ago"}</span>
                <span>Now</span>
              </div>
            </div>
          </div>

          {/* Hosts Status */}
          <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
            <h2 className="text-xl font-bold mb-6">Host Status</h2>
            <div className="grid grid-cols-4 gap-4">
              {hosts.map((host) => (
                <div
                  key={host.id}
                  className={`bg-slate-800/50 border rounded-xl p-4 hover:border-blue-500/50 transition-all ${
                    host.status === "critical"
                      ? "border-red-500/30"
                      : host.status === "warning"
                        ? "border-yellow-500/30"
                        : "border-slate-700"
                  }`}
                >
                  <div className="flex items-center justify-between mb-4">
                    <div
                      className={`w-3 h-3 rounded-full ${
                        host.status === "healthy"
                          ? "bg-green-400 animate-pulse"
                          : host.status === "warning"
                            ? "bg-yellow-400 animate-pulse"
                            : "bg-red-400 animate-pulse"
                      }`}
                    ></div>
                    {host.alerts > 0 && (
                      <span className="bg-red-500/20 text-red-400 text-xs font-bold px-2 py-0.5 rounded-full">
                        {host.alerts}
                      </span>
                    )}
                  </div>
                  <h3 className="font-semibold text-white mb-3">{host.name}</h3>
                  <div className="space-y-2 text-xs">
                    <div className="flex justify-between">
                      <span className="text-slate-400">CPU</span>
                      <span className={getMetricColor(host.cpu, 75)}>
                        {host.cpu}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Memory</span>
                      <span className={getMetricColor(host.memory, 75)}>
                        {host.memory}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Disk</span>
                      <span className={getMetricColor(host.disk, 75)}>
                        {host.disk}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Uptime</span>
                      <span className="text-green-400">{host.uptime}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Alerts View */}
      {activeView === "alerts" && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search alerts..."
                  className="bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Severity</option>
                <option>Critical</option>
                <option>Warning</option>
                <option>Info</option>
              </select>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Status</option>
                <option>Firing</option>
                <option>Resolved</option>
                <option>Acknowledged</option>
              </select>
            </div>
          </div>

          <div className="space-y-3">
            {alerts.map((alert) => (
              <div
                key={alert.id}
                className={`bg-slate-900/50 backdrop-blur-xl border rounded-xl p-6 transition-all hover:border-blue-500/50 ${
                  alert.severity === "critical"
                    ? "border-red-500/30"
                    : alert.severity === "warning"
                      ? "border-yellow-500/30"
                      : "border-slate-800"
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4 flex-1">
                    <div
                      className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                        alert.severity === "critical"
                          ? "bg-red-500/20"
                          : alert.severity === "warning"
                            ? "bg-yellow-500/20"
                            : "bg-blue-500/20"
                      }`}
                    >
                      {alert.severity === "critical" ? (
                        <AlertTriangle className="w-6 h-6 text-red-400" />
                      ) : alert.severity === "warning" ? (
                        <AlertCircle className="w-6 h-6 text-yellow-400" />
                      ) : (
                        <Info className="w-6 h-6 text-blue-400" />
                      )}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <h3 className="text-lg font-semibold text-white">
                          {alert.title}
                        </h3>
                        <span
                          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold border ${getSeverityColor(alert.severity)}`}
                        >
                          {alert.severity}
                        </span>
                        {alert.status === "resolved" && (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-green-500/20 text-green-400 border border-green-500/30">
                            Resolved
                          </span>
                        )}
                        {alert.acknowledged && (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-blue-500/20 text-blue-400 border border-blue-500/30">
                            Acknowledged
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-slate-300 mb-3">
                        {alert.description}
                      </p>
                      <div className="flex items-center space-x-6 text-sm text-slate-400">
                        <div className="flex items-center space-x-2">
                          <Server className="w-4 h-4" />
                          <span>{alert.host}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Gauge className="w-4 h-4" />
                          <span>
                            {alert.metric}: {alert.value} / {alert.threshold}
                          </span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Clock className="w-4 h-4" />
                          <span>{alert.time}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    {!alert.acknowledged && alert.status === "firing" && (
                      <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-semibold transition-all">
                        Acknowledge
                      </button>
                    )}
                    <button className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-all">
                      <MoreVertical className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Services View */}
      {activeView === "services" && (
        <div className="space-y-6">
          <div className="grid grid-cols-3 gap-6">
            {services.map((service, idx) => (
              <div
                key={idx}
                className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6 hover:border-blue-500/50 transition-all"
              >
                <div className="flex items-center justify-between mb-4">
                  <div
                    className={`w-3 h-3 rounded-full ${
                      service.status === "healthy"
                        ? "bg-green-400 animate-pulse"
                        : "bg-red-400 animate-pulse"
                    }`}
                  ></div>
                  <span
                    className={`text-sm font-semibold ${
                      service.status === "healthy"
                        ? "text-green-400"
                        : "text-red-400"
                    }`}
                  >
                    {service.status}
                  </span>
                </div>
                <h3 className="text-lg font-semibold text-white mb-4">
                  {service.name}
                </h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Uptime</span>
                    <span className="text-white font-medium">
                      {service.uptime}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Latency</span>
                    <span className="text-white font-medium">
                      {service.latency}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Alert Rules View */}
      {activeView === "metrics" && (
        <div className="space-y-6">
          <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
            <h2 className="text-xl font-bold mb-6">Alert Rules</h2>
            <div className="space-y-3">
              {alertRules.map((rule) => (
                <div
                  key={rule.id}
                  className="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg hover:bg-slate-800/50 transition-all"
                >
                  <div className="flex items-center space-x-4 flex-1">
                    <div
                      className={`w-3 h-3 rounded-full ${rule.enabled ? "bg-green-400" : "bg-slate-600"}`}
                    ></div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-1">
                        <h4 className="font-semibold text-white">
                          {rule.name}
                        </h4>
                        <span
                          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold border ${getSeverityColor(rule.severity)}`}
                        >
                          {rule.severity}
                        </span>
                      </div>
                      <p className="text-sm text-slate-400 mb-2">
                        {rule.condition}
                      </p>
                      <div className="flex items-center space-x-2">
                        {rule.notifications.map((notif, idx) => (
                          <span
                            key={idx}
                            className="inline-flex items-center px-2 py-1 rounded bg-slate-700 text-xs"
                          >
                            {notif === "email" && (
                              <Mail className="w-3 h-3 mr-1" />
                            )}
                            {notif === "slack" && (
                              <MessageSquare className="w-3 h-3 mr-1" />
                            )}
                            {notif === "sms" && (
                              <Phone className="w-3 h-3 mr-1" />
                            )}
                            {notif === "webhook" && (
                              <Webhook className="w-3 h-3 mr-1" />
                            )}
                            {notif}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <button className="p-2 hover:bg-slate-700 rounded-lg transition-colors">
                      <Settings className="w-4 h-4" />
                    </button>
                    <button
                      className={`px-3 py-1 rounded-lg text-sm font-semibold transition-all ${
                        rule.enabled
                          ? "bg-green-600 hover:bg-green-700"
                          : "bg-slate-700 hover:bg-slate-600"
                      }`}
                    >
                      {rule.enabled ? "Enabled" : "Disabled"}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Notification Channels */}
          <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6">
            <h2 className="text-xl font-bold mb-6">Notification Channels</h2>
            <div className="grid grid-cols-4 gap-4">
              {[
                { name: "Email", icon: Mail, configured: true, count: 3 },
                {
                  name: "Slack",
                  icon: MessageSquare,
                  configured: true,
                  count: 2,
                },
                { name: "SMS", icon: Phone, configured: false, count: 0 },
                { name: "Webhook", icon: Webhook, configured: true, count: 1 },
              ].map((channel, idx) => (
                <div
                  key={idx}
                  className="bg-slate-800/30 rounded-lg p-4 hover:bg-slate-800/50 transition-all"
                >
                  <div className="flex items-center justify-between mb-3">
                    <channel.icon
                      className={`w-6 h-6 ${channel.configured ? "text-green-400" : "text-slate-500"}`}
                    />
                    <div
                      className={`w-2 h-2 rounded-full ${channel.configured ? "bg-green-400" : "bg-slate-600"}`}
                    ></div>
                  </div>
                  <h4 className="font-semibold text-white mb-1">
                    {channel.name}
                  </h4>
                  <p className="text-xs text-slate-400">
                    {channel.configured
                      ? `${channel.count} configured`
                      : "Not configured"}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Logs View */}
      {activeView === "logs" && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search logs..."
                  className="bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-96"
                />
              </div>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Hosts</option>
                {hosts.map((h) => (
                  <option key={h.id}>{h.name}</option>
                ))}
              </select>
              <select className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm">
                <option>All Levels</option>
                <option>Error</option>
                <option>Warning</option>
                <option>Info</option>
                <option>Debug</option>
              </select>
            </div>
            <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all flex items-center space-x-2">
              <Download className="w-4 h-4" />
              <span>Export Logs</span>
            </button>
          </div>

          <div className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl overflow-hidden">
            <div className="bg-slate-950 p-4 font-mono text-xs space-y-1">
              {[
                {
                  time: "2024-12-20 15:34:21",
                  level: "ERROR",
                  host: "L4-Dell",
                  message: "CPU threshold exceeded: 89%",
                },
                {
                  time: "2024-12-20 15:33:45",
                  level: "WARN",
                  host: "L2-Yoga",
                  message: "Memory usage high: 78%",
                },
                {
                  time: "2024-12-20 15:32:10",
                  level: "INFO",
                  host: "L1-Vivobook",
                  message: "Snapshot completed: production-db",
                },
                {
                  time: "2024-12-20 15:30:55",
                  level: "ERROR",
                  host: "L3-TUF",
                  message: "Service health check failed: nomad-client",
                },
                {
                  time: "2024-12-20 15:29:30",
                  level: "INFO",
                  host: "L2-Yoga",
                  message: "Volume attached: vol-002",
                },
                {
                  time: "2024-12-20 15:28:15",
                  level: "WARN",
                  host: "Network",
                  message: "High latency detected: 145ms",
                },
                {
                  time: "2024-12-20 15:27:00",
                  level: "INFO",
                  host: "L1-Vivobook",
                  message: "Backup completed: full-system",
                },
                {
                  time: "2024-12-20 15:25:45",
                  level: "DEBUG",
                  host: "L3-TUF",
                  message: "Container started: web-app-01",
                },
                {
                  time: "2024-12-20 15:24:30",
                  level: "INFO",
                  host: "L4-Dell",
                  message: "VM migration completed: vm-005",
                },
                {
                  time: "2024-12-20 15:23:15",
                  level: "WARN",
                  host: "L1-Vivobook",
                  message: "Disk I/O spike detected",
                },
              ].map((log, idx) => (
                <div
                  key={idx}
                  className="flex items-start space-x-3 hover:bg-slate-800/50 p-2 rounded transition-all"
                >
                  <span className="text-slate-500">{log.time}</span>
                  <span
                    className={`font-semibold ${
                      log.level === "ERROR"
                        ? "text-red-400"
                        : log.level === "WARN"
                          ? "text-yellow-400"
                          : log.level === "INFO"
                            ? "text-blue-400"
                            : "text-slate-400"
                    }`}
                  >
                    [{log.level}]
                  </span>
                  <span className="text-cyan-400">{log.host}</span>
                  <span className="text-slate-300">{log.message}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Hosts Detail View */}
      {activeView === "hosts" && (
        <div className="space-y-6">
          {hosts.map((host) => (
            <div
              key={host.id}
              className="bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-xl p-6"
            >
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center space-x-4">
                  <div
                    className={`w-4 h-4 rounded-full ${
                      host.status === "healthy"
                        ? "bg-green-400 animate-pulse"
                        : host.status === "warning"
                          ? "bg-yellow-400 animate-pulse"
                          : "bg-red-400 animate-pulse"
                    }`}
                  ></div>
                  <div>
                    <h3 className="text-xl font-bold text-white">
                      {host.name}
                    </h3>
                    <p className="text-sm text-slate-400">
                      Uptime: {host.uptime}
                    </p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  {host.alerts > 0 && (
                    <span className="bg-red-500/20 text-red-400 text-sm font-bold px-3 py-1 rounded-full border border-red-500/30">
                      {host.alerts} Alert{host.alerts > 1 ? "s" : ""}
                    </span>
                  )}
                  <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-semibold transition-all">
                    View Details
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-6">
                <div className="bg-slate-800/30 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <Cpu className="w-5 h-5 text-blue-400" />
                    <span
                      className={`text-2xl font-bold ${getMetricColor(host.cpu, 75)}`}
                    >
                      {host.cpu}%
                    </span>
                  </div>
                  <p className="text-sm text-slate-400">CPU Usage</p>
                  <div className="mt-3 w-full bg-slate-700 rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-2 rounded-full transition-all ${
                        host.cpu >= 85
                          ? "bg-red-500"
                          : host.cpu >= 75
                            ? "bg-yellow-500"
                            : "bg-blue-500"
                      }`}
                      style={{ width: `${host.cpu}%` }}
                    ></div>
                  </div>
                </div>

                <div className="bg-slate-800/30 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <Server className="w-5 h-5 text-purple-400" />
                    <span
                      className={`text-2xl font-bold ${getMetricColor(host.memory, 75)}`}
                    >
                      {host.memory}%
                    </span>
                  </div>
                  <p className="text-sm text-slate-400">Memory Usage</p>
                  <div className="mt-3 w-full bg-slate-700 rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-2 rounded-full transition-all ${
                        host.memory >= 85
                          ? "bg-red-500"
                          : host.memory >= 75
                            ? "bg-yellow-500"
                            : "bg-purple-500"
                      }`}
                      style={{ width: `${host.memory}%` }}
                    ></div>
                  </div>
                </div>

                <div className="bg-slate-800/30 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <HardDrive className="w-5 h-5 text-orange-400" />
                    <span
                      className={`text-2xl font-bold ${getMetricColor(host.disk, 75)}`}
                    >
                      {host.disk}%
                    </span>
                  </div>
                  <p className="text-sm text-slate-400">Disk Usage</p>
                  <div className="mt-3 w-full bg-slate-700 rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-2 rounded-full transition-all ${
                        host.disk >= 85
                          ? "bg-red-500"
                          : host.disk >= 75
                            ? "bg-yellow-500"
                            : "bg-orange-500"
                      }`}
                      style={{ width: `${host.disk}%` }}
                    ></div>
                  </div>
                </div>

                <div className="bg-slate-800/30 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <Network className="w-5 h-5 text-cyan-400" />
                    <span className="text-2xl font-bold text-cyan-400">
                      {Math.round(metrics.network)}
                    </span>
                  </div>
                  <p className="text-sm text-slate-400">Network (Mbps)</p>
                  <div className="mt-3 w-full bg-slate-700 rounded-full h-2 overflow-hidden">
                    <div
                      className="bg-cyan-500 h-2 rounded-full transition-all"
                      style={{ width: `${(metrics.network / 3000) * 100}%` }}
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Alert Modal */}
      {showAlertModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-6">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Create Alert Rule</h2>
              <button
                onClick={() => setShowAlertModal(false)}
                className="p-2 hover:bg-slate-800 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Rule Name
                </label>
                <input
                  type="text"
                  placeholder="High CPU Alert"
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Metric
                  </label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>CPU Usage</option>
                    <option>Memory Usage</option>
                    <option>Disk Usage</option>
                    <option>Network Latency</option>
                    <option>Service Health</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Severity
                  </label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>Critical</option>
                    <option>Warning</option>
                    <option>Info</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Condition
                  </label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>Greater than</option>
                    <option>Less than</option>
                    <option>Equal to</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Threshold
                  </label>
                  <input
                    type="number"
                    placeholder="85"
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Duration
                  </label>
                  <input
                    type="text"
                    placeholder="10m"
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Notification Channels
                </label>
                <div className="grid grid-cols-2 gap-3">
                  {["Email", "Slack", "SMS", "Webhook"].map((channel) => (
                    <label
                      key={channel}
                      className="flex items-center space-x-2 bg-slate-800 p-3 rounded-lg cursor-pointer hover:bg-slate-700 transition-all"
                    >
                      <input
                        type="checkbox"
                        className="w-4 h-4 rounded border-slate-700 bg-slate-800 text-blue-600"
                      />
                      <span className="text-sm">{channel}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  onClick={() => setShowAlertModal(false)}
                  className="flex-1 px-6 py-3 bg-slate-800 hover:bg-slate-700 rounded-lg font-semibold transition-all"
                >
                  Cancel
                </button>
                <button className="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 rounded-lg font-semibold transition-all">
                  Create Alert Rule
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
