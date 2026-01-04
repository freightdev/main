job "openwebui" {
  datacenters = ["ai-lab"]
  type = "service"

  group "webui" {
    count = 1

    network {
      port "http" {
        static = 3000
      }
    }

    service {
      name = "openwebui"
      port = "http"

      tags = [
        "ai",
        "webui"
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "openwebui" {
      driver = "podman"

      config {
        image = "ghcr.io/open-webui/open-webui:main"

        ports = ["http"]

        volumes = [
          "openwebui-data:/app/backend/data"
        ]

        args = [
          "--host", "0.0.0.0",
          "--port", "3000"
        ]
      }

      env {
        OLLAMA_BASE_URL = "http://ollama.local:11434"
        WEBUI_SECRET_KEY = "your-secret-key-here"
        DATABASE_URL = "duckdb:///app/backend/data/webui.db"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }
    }
  }
}
