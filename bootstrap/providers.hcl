provider "aws" {
    region = "us-east-1"
    instance_type = "t2.large"
    credential "default" {
        access_key_id = "..."
        secret_access_key = "..."
    }
}

provider "kubernetes" {
    cluster "kube" {
        ca_file = "..."
        server_uri = "kube.local"
    }

    client "ci" {
        cert_file = "..."
        key_file = "..."
    }
}

provider "docker" {
    host = "..."
}
