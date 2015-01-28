require "spec_helper"

module AwsWrapper
  module Ec2
    describe Instance do

      VPC_NAME      = "vpc-instance-test"
      VPC_CIDR      = "10.10.0.0/16"
      SUBNET_NAME   = "sn-instance-test"
      SUBNET_CIDR   = "10.10.1.0/24"
      INSTANCE_NAME = "instance-test"
      INSTANCE_AMI  = "ami-4985b048"
      INSTANCE_TYPE = "t2.micro"
      SECURITY_GROUP_NAME = "instance-test-sg"
      DESCRIPTION = "Security Group for testing"

      created_vpcs = []
      created_subnets = []
      created_security_groups = []
      created_instances = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc_info = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc_info[:vpc_id]
        subnet_info = AwsWrapper::Ec2::Subnet.create(SUBNET_NAME, SUBNET_CIDR, VPC_NAME)
        created_subnets << subnet_info[:subnet_id]
        sg_info = AwsWrapper::Ec2::SecurityGroup.create(
          SECURITY_GROUP_NAME, DESCRIPTION, vpc_info[:vpc_id]
        )
        created_security_groups << sg_info[:group_id]
      end

      it "creates instance" do
        options = {}
        subnet = AwsWrapper::Ec2::Subnet.find(SUBNET_NAME)
        options[:subnet] = subnet[:subnet_id]
        instance = AwsWrapper::Ec2::Instance.create(
          INSTANCE_NAME, INSTANCE_AMI, INSTANCE_TYPE, options
        )
        created_instances << instance[:instance_id]
        expect(AwsWrapper::Ec2::Instance.exists?(INSTANCE_NAME)).to be true
      end

      it "enables sourceDestCheck" do
        instance = AwsWrapper::Ec2::Instance.new(INSTANCE_NAME)
        instance.enable_source_dest_check(true)
        expect(instance.source_dest_check).to be true
      end

      it "disables sourceDestCheck" do
        instance = AwsWrapper::Ec2::Instance.new(INSTANCE_NAME)
        instance.enable_source_dest_check(false)
        expect(instance.source_dest_check).not_to be true
      end

      it "associates security group" do
        instance = AwsWrapper::Ec2::Instance.new(INSTANCE_NAME)
        instance.associate_security_group(SECURITY_GROUP_NAME)
        expect(instance.associated_with?(SECURITY_GROUP_NAME)).to be true
      end

      it "disassiciates security group" do
        instance = AwsWrapper::Ec2::Instance.new(INSTANCE_NAME)
        instance.disassociate_security_group(SECURITY_GROUP_NAME)
        expect(instance.associated_with?(SECURITY_GROUP_NAME)).not_to be true
      end

      it "deletes instance" do
        instance = AwsWrapper::Ec2::Instance.new(INSTANCE_NAME)
        AwsWrapper::Ec2::Instance.delete(INSTANCE_NAME)
        retry_count = 5
        while instance.status == :shutting_down and retry_count > 0 do
          sleep 3
          retry_count = retry_count - 1
        end
        expect(instance.status == :terminated).to be true
      end

      after(:all) do
        created_instances.each do |instance_id|
          AwsWrapper::Ec2::Instance.delete(instance_id)
        end
        created_security_groups.each do |group_id|
          AwsWrapper::Ec2::SecurityGroup.delete(group_id)
        end
        created_subnets.each do |subnet_id|
          AwsWrapper::Ec2::Subnet.delete!(subnet_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(vpc_id)
        end
      end
    end
  end
end
