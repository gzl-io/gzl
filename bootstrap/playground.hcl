name = "gzl"
description = "gzl continuous integration"

source {
  uri = "git://user@github.com/gzl-io/gzl"
  # ideally there's a webhook or API available, but as a stopgap.
  interval = 60
}

resources {
  resource "local" {

  }

  resource "docker" {

  }

  resource "kubernetes" {

  }
}

notify "slack" {
  hook_uri = "https://..."
}

stage "build" {
  command "go build" {
    options = ["-a"]
    output_filter = "grep -C 10 -i error"
  }
  notify_before = true
}

stage "test" {
  tee {
    command "go test" {
      options = ["-run unit"]
    }

    command "go test" {
      options = ["-run component"]
    }
  }
}

stage "deploy" {
  notify_after = true
}
