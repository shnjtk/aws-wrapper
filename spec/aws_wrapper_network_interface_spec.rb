require 'spec_helper'

module AwsWrapper
  module Ec2
    describe NetworkInterface do

      VPC_NAME = "eni-test-vpc"
      VPC_CIDR = "10.10.0.0/16"
      SUBNET_NAME = "eni-test-subnet"
      SUBNET_CIDR = "10.10.10.0/24"
      INTERFACE_NAME = "eni-test-interface"
      SECURITY_GROUP_NAME = "eni-test-sg"
      SECURITY_GROUP_DESCRIPTION = "security group for ENI test"
      INSTANCE_NAME = "eni-test-instance"
      INSTANCE_AMI  = "ami-4985b048"
      INSTANCE_TYPE = "t2.micro"

      created_vpcs = []
      created_subnets = []
      created_security_groups = []
      created_interfaces = []
      created_instances = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc[:vpc_id]
        subnet = AwsWrapper::Ec2::Subnet.create(SUBNET_NAME, SUBNET_CIDR, VPC_NAME)
        created_subnets << subnet[:subnet_id]
        security_group = AwsWrapper::Ec2::SecurityGroup.create(
          SECURITY_GROUP_NAME, SECURITY_GROUP_DESCRIPTION, vpc[:vpc_id]
        )
        created_security_groups << security_group[:security_group_id]
        options = {}
        options[:subnet] = subnet[:subnet_id]
        instance = AwsWrapper::Ec2::Instance.create(
          INSTANCE_NAME, INSTANCE_AMI, INSTANCE_TYPE, options
        )
        created_instances << instance[:instance_id]
      end

      it "creates network interface named '#{INTERFACE_NAME}'" do
        interface = AwsWrapper::Ec2::NetworkInterface.create(INTERFACE_NAME, SUBNET_NAME)
        created_interfaces << interface[:network_interface_id]
        expect(AwsWrapper::Ec2::NetworkInterface.exists?(INTERFACE_NAME)).to be true
      end

      it "sets security group" do
        interface = AwsWrapper::Ec2::NetworkInterface.new(INTERFACE_NAME)
        interface.set_security_groups([SECURITY_GROUP_NAME])
        expect(interface.has_security_group?(SECURITY_GROUP_NAME)).to be true
      end

      it "attaches to the EC2 instance" do
        interface = AwsWrapper::Ec2::NetworkInterface.new(INTERFACE_NAME)
        interface.attach(INSTANCE_NAME)
        expect(interface.attached?(INSTANCE_NAME)).to be true
      end

      it "detaches from the EC2 instance" do
        interface = AwsWrapper::Ec2::NetworkInterface.new(INTERFACE_NAME)
        interface.detach
        expect(interface.attached?(INSTANCE_NAME)).not_to be true
      end

      it "deletes network interface" do
        AwsWrapper::Ec2::NetworkInterface.delete(INTERFACE_NAME)
        expect(AwsWrapper::Ec2::NetworkInterface.exists?(INTERFACE_NAME)).not_to be true
      end

      after(:all) do
        created_instances.each do |instance_id|
          AwsWrapper::Ec2::Instance.delete(instance_id)
        end
        created_interfaces.each do |interface_id|
          AwsWrapper::Ec2::NetworkInterface.delete(interface_id)
        end
        created_security_groups.each do |security_group_id|
          AwsWrapper::Ec2::SecurityGroup.delete(security_group_id)
        end
        created_subnets.each do |subnet_id|
          AwsWrapper::Ec2::Subnet.delete!(subnet_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete!(vpc_id)
        end
      end
    end
  end
end
