locals {
  traefik_airlines_services = ["customers", "employees", "flights", "tickets"]
}

resource "kubernetes_ingress_v1" "services" {
  for_each = toset(local.traefik_airlines_services)

  metadata {
    name      = "api-ingress-${each.value}-secure"
    namespace = "traefik-airlines"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = "traefik-airlines"
    }
  }

  spec {
    rule {
      host = "${each.value}.traefik-airlines.test.sslip.io"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "${each.value}-app"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}
