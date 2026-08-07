resource "uptimekuma_notification_telegram" "alert" {
  name       = "Watchdog Telegram"
  bot_token  = var.telegram_bot_token
  chat_id    = var.telegram_chat_id
  is_active  = true
  is_default = true
}

# The public path: DNS, the internet, the hawkfield router and the ingress all
# have to work. This is the one that goes dark when the site does.
resource "uptimekuma_monitor_http" "public" {
  name             = "hawkfield public"
  url              = "https://clincha.co.uk"
  interval         = 60
  active           = true
  notification_ids = [uptimekuma_notification_telegram.alert.id]
}

locals {
  # The private path, over the site-to-site link. Losing these while the public
  # monitor stays up means the link broke, not the site.
  tcp_targets = {
    "hawkfield ingress" = { hostname = "10.1.2.205", port = 443 }
    "hawkstore"         = { hostname = "10.1.2.10", port = 443 }
    # All three control planes individually: hawk-1 carries the VIP and does
    # not fail over, so one node down is not the same event as the cluster
    # being gone.
    "k8s-hawk-1 api" = { hostname = "10.1.2.101", port = 6443 }
    "k8s-hawk-2 api" = { hostname = "10.1.2.102", port = 6443 }
    "k8s-hawk-3 api" = { hostname = "10.1.2.103", port = 6443 }
  }
}

resource "uptimekuma_monitor_tcp_port" "target" {
  for_each = local.tcp_targets

  name             = each.key
  hostname         = each.value.hostname
  port             = each.value.port
  interval         = 60
  active           = true
  notification_ids = [uptimekuma_notification_telegram.alert.id]
}

# Dead-man's switch. Alertmanager pushes here every minute; five minutes of
# silence means the alerting pipeline itself has died, which probing hawkfield
# from outside would never reveal — the ingress can be perfectly healthy while
# nothing is able to notify anyone.
resource "uptimekuma_monitor_push" "alerting" {
  name             = "hawkfield alerting heartbeat"
  interval         = 300
  max_retries      = 0
  active           = true
  notification_ids = [uptimekuma_notification_telegram.alert.id]
}

output "alerting_push_token" {
  value     = uptimekuma_monitor_push.alerting.push_token
  sensitive = true
}
