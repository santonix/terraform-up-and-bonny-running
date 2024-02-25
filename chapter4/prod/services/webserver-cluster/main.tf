
provider "aws" {
  region = "us-east-2"
}


module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster" // Path to the module code
  cluster_name           = "webservers-prod"                             // Name of the web server cluster
  db_remote_state_bucket = "terraform-up-and-bonny-running-state"        // Bucket where the Terraform state file is stored
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"    // Path to the Terraform state file for the database
  instance_type          = "m4.large"                                    // Type of EC2 instance for the cluster
  min_size               = 2                                             // Minimum number of instances in the cluster
  max_size               = 10                                            // Maximum number of instances in the cluster
}


// This block defines an AWS Autoscaling Schedule resource named "scale_out_during_business_hours".
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours" // Name of the scheduled action.
  min_size              = 2                                 // Minimum number of instances in the Auto Scaling group.
  max_size              = 10                                // Maximum number of instances in the Auto Scaling group.
  desired_capacity      = 10                                // Desired number of instances in the Auto Scaling group.
  recurrence            = "0 9 * * *"                       // Recurrence pattern for the scheduled action (every day at 9 AM).

  // Specifies the name of the Auto Scaling group targeted by this schedule.
  autoscaling_group_name = module.webserver_cluster.asg_name
}

// This block defines another AWS Autoscaling Schedule resource named "scale_in_at_night".
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night" // Name of the scheduled action.
  min_size              = 2                   // Minimum number of instances in the Auto Scaling group.
  max_size              = 10                  // Maximum number of instances in the Auto Scaling group.
  desired_capacity      = 2                   // Desired number of instances in the Auto Scaling group.
  recurrence            = "0 17 * * *"        // Recurrence pattern for the scheduled action (every day at 5 PM).

  // Specifies the name of the Auto Scaling group targeted by this schedule.
  autoscaling_group_name = module.webserver_cluster.asg_name
}















