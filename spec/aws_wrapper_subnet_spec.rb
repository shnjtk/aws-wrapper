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
        AwsWrapper::Ec2::Subnet.create(SUBNET_NAME, SUBNET_CIDR, {:name => VPC_NAME})
        expect(AwsWrapper::Ec2::Subnet.exists?(:name => SUBNET_NAME)).to be true
      end

      it "has a Subnet named \'#{SUBNET_NAME}\' with CIDR block \'#{SUBNET_CIDR}\'" do
        subnet_info = AwsWrapper::Ec2::Subnet.find(:name => SUBNET_NAME)
        expect(subnet_info).not_to be nil
        expect(subnet_info[:cidr_block]).to eql SUBNET_CIDR
      end

      it "sets a route table" do
        rt = AwsWrapper::Ec2::RouteTable.create(RTABLE_NAME, {:name => VPC_NAME})
        created_rtables << rt[:route_table_id]
        subnet = AwsWrapper::Ec2::Subnet.new(:name => SUBNET_NAME)
        subnet.set_route_table(:name => RTABLE_NAME)
        expect(subnet.associated?(:name => RTABLE_NAME)).to be true
      end

      it "deletes a Subnet named \'#{VPC_NAME}\'" do
        AwsWrapper::Ec2::Subnet.delete(:name => SUBNET_NAME)
        expect(AwsWrapper::Ec2::Subnet.exists?(:name => SUBNET_NAME)).not_to be true
      end

      after(:all) do
        created_subnets.each do |subnet_id|
          AwsWrapper::Ec2::Subnet.delete(:id => subnet_id)
        end
        created_rtables.each do |rtable_id|
          AwsWrapper::Ec2::RouteTable.delete(:id => rtable_id)
        end
        created_igws.each do |igw_id|
          AwsWrapper::Ec2::InternetGateway.delete!(:id => igw_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(:id => vpc_id)
        end
      end

    end
  end
end
