terraform {
  cloud {
    organization = "clinch-home"

    workspaces {
      name = "github"
    }
  }
}