output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "bastion_security_group_id" {
  value = module.security.bastion_sg_id
}

output "alb_security_group_id" {
  value = module.security.alb_sg_id
}

output "private_ec2_security_group_id" {
  value = module.security.private_ec2_sg_id
}

output "bastion_private_ip" {
  value = module.bastion.bastion_private_ip
}
output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "ec2_iam_role_name" {
  value = module.iam.role_name
}

output "ec2_instance_profile_name" {
  value = module.iam.instance_profile_name
}




# alb out put 

output "alb_dns_name" {
  description = "dns name of alb"
  value       = module.alb.alb_dns_name
}
output "alb_target_group_arn" {
  description = "target grp arn"
  value       = module.alb.target_group_arn
}


#-------------
#cloud watch output
#-------------

output "cloudwatch_high_cpu_alarm" {
  value = module.cloudWatch.high_cpu_alarm_name
}

output "cloudwatch_unhealthy_target_alarm" {
  value = module.cloudWatch.unhealthy_target_alarm_name
}

output "cloudwatch_request_count_alarm" {
  value = module.cloudWatch.request_count_alarm_name
}

output "cloudwatch_response_time_alarm" {
  value = module.cloudWatch.response_time_alarm_name
}

output "cloudwatch_http_5xx_alarm" {
  value = module.cloudWatch.http_5xx_alarm_name
}
