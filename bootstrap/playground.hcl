gzl {
    name = "line"
    description = "Line Project"

    source {
        src = "."
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

    stage "build" {
        steps = [

        ]
    }

    stage "test" {
        steps = [

        ]
    }

    stage "deploy" {
        steps = [

        ]
    }
}
