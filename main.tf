# vpc creation
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support

  tags = merge(
    var.common_tags,
    {
      Name = var.project_name
    },
      var.vpc_tags
  )
  }
  
#  internet gateway creation

 resource "aws_internet_gateway" "gw" {
   vpc_id = aws_vpc.main.id

   tags =  merge (
     var.common_tags,
   {
      Name = var.project_name
   },
     var.igw_tags
   )
      }

# we need to automatically fetch the az's because if it is left to user he may create subnets in  4,5 availabilty zones. I want 

# the subnets to get created in only 1a and 1b so i using datasource to get only 2 az's. Data source will fetch the required az's

# in that region.

# public subnet creation

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  map_public_ip_on_launch = true      # if you launch any ec2 instance in this subnet by default you get public ip
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-${local.azs[count.index]}"
    }
  )
}

# private subnet creation

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private-${local.azs[count.index]}"
    }
  )
}

# database subnet creation

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-database-${local.azs[count.index]}"
    }
  )
}

# creating public route table and route for public subnets

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    var.common_tags,
    {
       Name = "${var.project_name}-public"
    },
    var.public_route_table_tags
  )
   }

# creating elastic ip ..

resource "aws_eip" "eip" {
  domain = "vpc"  
} # Elastic IP can be associated with either the vpc domain or wth EC2. In this case, it's being associated with the VPC domain.


# creating NAT gateway

resource "aws_nat_gateway" "nat-gw" {
allocation_id = aws_eip.eip.id
subnet_id     = aws_subnet.public[0].id

tags = merge(
    var.common_tags,
    {
      Name = var.project_name # if var.natgateway_tags is not declared then resource name will be this one
    },
    var.natgateway_tags  # if you assign value to this natgateway_tags in user module with Name attribute that will replace the Name = var.project_name
  )
    depends_on = [aws_internet_gateway.gw]
}  


# creating private route table and route for private subnets

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = merge(
    var.common_tags,
    {
       Name = "${var.project_name}-private"
    },
    var.private_route_table_tags
  )
}

# creating database route table and route for database subnets 

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = merge(
    var.common_tags,
    {
       Name = "${var.project_name}-database"
    },
    var.database_route_table_tags
  )
}

# associating public subnets(1a and 1b) to public route table
 resource "aws_route_table_association" "public" {
   count = length(var.public_subnet_cidr)
   subnet_id      = element(aws_subnet.public[*].id, count.index)
   route_table_id = aws_route_table.public.id
 }

 # associating private subnets(1a and 1b) to private route table
 resource "aws_route_table_association" "private" {
   count = length(var.private_subnet_cidr)
   subnet_id      = element(aws_subnet.private[*].id, count.index)
   route_table_id = aws_route_table.private.id
 }

# associating database subnets(1a and 1b) to database route table
 resource "aws_route_table_association" "database" {
   count = length(var.database_subnet_cidr)
   subnet_id      = element(aws_subnet.database[*].id, count.index)
   route_table_id = aws_route_table.database.id
 }


resource "aws_db_subnet_group" "roboshop_db_group" {
  name       = var.project_name
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-database-group"
    },
    var.db_subnet_group_tags

  )
  }

