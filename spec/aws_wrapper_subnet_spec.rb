require "spec_helper"

module AwsWrapper
  module Ec2
    describe Subnet do

      VPC_NAME    = "vpc-subnet-test"
      VPC_CIDR    = "10.10.0.0/16"
      IGW_NAME    = "igw-subnet-test"
      SUBNET_NAME = "sn-subnet-test"
      SUBNET_CIDR = "10.10.1.0/24"
      RTABLE_NAME = "rt-subnet-test"
      RTABLE_CIDR = "0.0.0.0/0"

      created_vpcs = []
      created_igws = []
      created_subnets = []
      created_rtables = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc_info = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc_info[:vpc_id]
      end

      it "creates a Subnet named \'#{SUBNET_NAME}\' with CIDR block \'#{SUBNET_CIDR}\'" do
        AwsWrapper::Ec2::Subnet.create(SUBNET_NAME, SUBNET_CIDR, VPC_NAME)
        expect(AwsWrapper::Ec2::Subnet.exists?(SUBNET_NAME)).to be true
      end

      it "has a Subnet named \'#{SUBNET_NAME}\' with CIDR block \'#{SUBNET_CIDR}\'" do
        subnet_info = AwsWrapper::Ec2::Subnet.find(SUBNET_NAME)
        expect(subnet_info).not_to be nil
        expect(subnet_info[:cidr_block]).to eql SUBNET_CIDR
      end

      it "sets a route table" do
        rt = AwsWrapper::Ec2::RouteTable.create(RTABLE_NAME, VPC_NAME)
        created_rtables << rt[:route_table_id]
        subnet = AwsWrapper::Ec2::Subnet.new(SUBNET_NAME)
        subnet.set_route_table(RTABLE_NAME)
        expect(subnet.associated?(RTABLE_NAME)).to be true
      end

      it "deletes a Subnet named \'#{VPC_NAME}\'" do
        AwsWrapper::Ec2::Subnet.delete(SUBNET_NAME)
        expect(AwsWrapper::Ec2::Subnet.exists?(SUBNET_NAME)).not_to be true
      end

      after(:all) do
        created_subnets.each do |subnet_id|
          AwsWrapper::Ec2::Subnet.delete(subnet_id)
        end
        created_rtables.each do |rtable_id|
          AwsWrapper::Ec2::RouteTable.delete(rtable_id)
        end
        created_igws.each do |igw_id|
          AwsWrapper::Ec2::InternetGateway.delete!(igw_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(vpc_id)
        end
      end

    end
  end
end
