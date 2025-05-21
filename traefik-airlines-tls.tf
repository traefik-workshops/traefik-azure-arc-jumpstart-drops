locals {
  aks_traefik_ip = "" //var.enableAKS && var.enableTraefik ? data.kubernetes_service.traefik.0.status.0.load_balancer.0.ingress.0.ip : ""
}

resource "kubernetes_ingress_v1" "customers" {
  metadata {
    name      = "api-ingress-customers-secure"
    namespace = "traefik-airlines"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = "traefik-airlines"
    }
  }

  spec {
    rule {
      host = "customers.traefik-airlines.${local.aks_traefik_ip}.sslip.io"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "customers-app"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  count = var.enableAKS && var.enableTraefikAirlinesTLS ? 1 : 0
  depends_on = [ azurerm_arc_kubernetes_flux_configuration.traefik_airlines ]
}

resource "kubernetes_ingress_v1" "employees" {
  metadata {
    name      = "api-ingress-employees-secure"
    namespace = "traefik-airlines"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = "traefik-airlines"
    }
  }

  spec {
    rule {
      host = "employees.traefik-airlines.${local.aks_traefik_ip}.sslip.io"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "employees-app"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  count = var.enableAKS && var.enableTraefikAirlinesTLS ? 1 : 0
  depends_on = [ azurerm_arc_kubernetes_flux_configuration.traefik_airlines ]
}

resource "kubernetes_ingress_v1" "flights" {
  metadata {
    name      = "api-ingress-flights-secure"
    namespace = "traefik-airlines"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = "traefik-airlines"
    }
  }

  spec {
    rule {
      host = "flights.traefik-airlines.${local.aks_traefik_ip}.sslip.io"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "flights-app"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  count = var.enableAKS && var.enableTraefikAirlinesTLS ? 1 : 0
  depends_on = [ azurerm_arc_kubernetes_flux_configuration.traefik_airlines ]
}

resource "kubernetes_ingress_v1" "tickets" {
  metadata {
    name      = "api-ingress-tickets-secure"
    namespace = "traefik-airlines"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = "traefik-airlines"
    }
  }

  spec {
    rule {
      host = "tickets.traefik-airlines.${local.aks_traefik_ip}.sslip.io"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "tickets-app"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  count = var.enableAKS && var.enableTraefikAirlinesTLS ? 1 : 0
  depends_on = [ azurerm_arc_kubernetes_flux_configuration.traefik_airlines ]
}
