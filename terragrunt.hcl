terraform {
  # Deploy version v0.0.3 in stage
  source = "../../../Dev/ap-southeast-1/ec2"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {

    name = "devops-project"

    environment = "dev"

    region = "ap-southeast-1"

    tags = {
        Environment = "dev",
        Terraform   = "true"
    }

    cidr_block = "172.16.0.0/16"

    public_subnet = [ "172.16.4.0/26", "172.16.4.64/26" ]

    private_subnet = [ "172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24" ]

    eks_ng_instance = "t3.large"

    availability_zone = ["ap-southeast-1a", "ap-southeast-1b"]

    taint_key = "key"

    taint_value = "value"
} 
