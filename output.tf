output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "public_subnets" {
  value = aws_subnet.public
}

output "private_subnets" {
  value = aws_subnet.private
}

output "local_subnets" {
  value = aws_subnet.local
}

output "private_route_table_id" {
  value = [
    for t in aws_route_table.private :
      t.id
  ]
}