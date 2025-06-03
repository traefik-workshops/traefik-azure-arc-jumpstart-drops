module "k3d" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/k3d?ref=main"

  // k3d- added automatically by k3d
  cluster_name = "traefik-demo"
}
