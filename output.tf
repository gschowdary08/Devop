output "vpc_id" {
  value = aws_vpc.main.id
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "fsx_dns" {
  value = aws_fsx_windows_file_system.fsx.dns_name
}
