terraform {
  cloud {
    organization = "clinch-home"

    workspaces {
      name = "clinch-home"
    }
  }
}