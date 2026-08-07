resource "uptimekuma_notification_telegram" "alert" {
  name       = "Uptime Kuma Alert"
  bot_token  = var.telegram_bot_token
  chat_id    = var.telegram_chat_id
  is_active  = true
  is_default = true
}

locals {
  # Adding a service is one entry here. Everything else follows from it.
  monitors = {
    plex = {
      # /identity answers without auth; the root path redirects to the web app.
      url = "https://plex.clinch-home.com/identity"
    }
    sonarr  = { url = "https://sonarr.clinch-home.com" }
    radarr  = { url = "https://radarr.clinch-home.com" }
    sabnzbd = { url = "https://sabnzbd.clinch-home.com" }
    bazarr  = { url = "https://bazarr.clinch-home.com" }
    tdarr   = { url = "https://tdarr.clinch-home.com" }
    immich  = { url = "https://immich.clinch-home.com" }
    ombi    = { url = "https://ombi.clinch-home.com" }
    tautulli = {
      # Root 303s to the login flow; /status is an unauthenticated health payload.
      url = "https://tautulli.clinch-home.com/status"
    }

    grafana = {
      # Root 302s to /login.
      url = "https://grafana.clinch-home.com/api/health"
    }
    prometheus = {
      # Root 302s to /query.
      url = "https://prometheus.clinch-home.com/-/healthy"
    }
    alloy = { url = "https://alloy.clinch-home.com/-/ready" }
    loki  = { url = "https://loki.clinch-home.com" }

    "clincha.co.uk" = { url = "https://clincha.co.uk" }
  }
}

resource "uptimekuma_monitor_http" "service" {
  for_each = local.monitors

  name             = each.key
  url              = each.value.url
  interval         = 60
  active           = true
  notification_ids = [uptimekuma_notification_telegram.alert.id]
}

resource "uptimekuma_status_page" "all" {
  slug      = "all"
  title     = "all"
  published = true

  public_group_list = [
    {
      name   = "Services"
      weight = 1
      monitor_list = [
        for key in sort(keys(local.monitors)) : {
          id = uptimekuma_monitor_http.service[key].id
        }
      ]
    }
  ]
}
