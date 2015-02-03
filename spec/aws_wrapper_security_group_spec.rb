require "spec_helper"

module AwsWrapper
  module Ec2
    describe SecurityGroup do

      VPC_NAME             = "vpc-securigy-group-test"
      VPC_CIDR             = "10.10.0.0/16"
      SUBNET_NAME          = "sn-security-group-test"
      SUBNET_CIDR          = "10.10.0.0/24"
      INTERFACE_NAME       = "eni-security-group-test"
      SECURITY_GROUP_NAME  = "vpc-security-group-test-sg"
      DESCRIPTION          = "Security Group for testing"
      INBOUND_PROTO        = AwsWrapper::Ec2::SecurityGroup::PROTO_TCP
      INBOUND_PORT         = 80
      INBOUND_SOURCE       = "0.0.0.0/0"
      OUTBOUND_PROTO       = AwsWrapper::Ec2::SecurityGroup::PROTO_ALL
      OUTBOUND_PORT        = AwsWrapper::Ec2::SecurityGroup::PORT_ALL
      OUTBOUND_DESTINATION = "0.0.0.0/0"
      INBOUND_PROTO_2      = AwsWrapper::Ec2::SecurityGroup::PROTO_ALL
      INBOUND_PORT_2       = AwsWrapper::Ec2::SecurityGroup::PORT_ALL
      INBOUND_SOURCE_2     = "0.0.0.0/0"

      created_vpcs = []
      created_subnets = []
      created_interfaces = []
      created_security_groups = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc_info = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc_info[:vpc_id]
        subnet = AwsWrapper::Ec2::Subnet.create(SUBNET_NAME, SUBNET_CIDR, VPC_NAME)
        created_subnets << subnet[:subnet_id]
        interface = AwsWrapper::Ec2::NetworkInterface.create(INTERFACE_NAME, SUBNET_NAME)
        created_interfaces << interface[:network_interface_id]
      end

      it "creates a SecurityGroup named \'#{SECURITY_GROUP_NAME}\'" do
        vpc = AwsWrapper::Ec2::Vpc.find(VPC_NAME)
        sg_info = AwsWrapper::Ec2::SecurityGroup.create(
          SECURITY_GROUP_NAME, DESCRIPTION, vpc[:vpc_id]
        )
        created_security_groups << sg_info[:group_id]
        expect(AwsWrapper::Ec2::SecurityGroup.exists?(SECURITY_GROUP_NAME)).to be true
      end

      it "adds inbound rule" do
        sg = AwsWrapper::Ec2::SecurityGroup.new(SECURITY_GROUP_NAME)
        sg.add_inbound_rule(INBOUND_PROTO, INBOUND_PORT, INBOUND_SOURCE)
        expect(sg.has_inbound_rule?(INBOUND_PROTO, INBOUND_PORT, INBOUND_SOURCE)).to be true
      end

      it "adds outbound rule" do
        sg = AwsWrapper::Ec2::SecurityGroup.new(SECURITY_GROUP_NAME)
        sg.add_outbound_rule(OUTBOUND_PROTO, OUTBOUND_PORT, OUTBOUND_DESTINATION)
        expect(sg.has_outbound_rule?(OUTBOUND_PROTO, OUTBOUND_PORT, OUTBOUND_DESTINATION)).to be true
      end

      it "removes inbound rule" do
        sg = AwsWrapper::Ec2::SecurityGroup.new(SECURITY_GROUP_NAME)
        sg.remove_inbound_rule(INBOUND_PROTO, INBOUND_PORT, INBOUND_SOURCE)
        expect(sg.has_inbound_rule?(INBOUND_PROTO, INBOUND_PORT, INBOUND_SOURCE)).not_to be true
      end

      it "removes outbound rule" do
        sg = AwsWrapper::Ec2::SecurityGroup.new(SECURITY_GROUP_NAME)
        sg.remove_outbound_rule(OUTBOUND_DESTINATION)
        expect(sg.has_outbound_rule?(OUTBOUND_PROTO, OUTBOUND_PORT, OUTBOUND_DESTINATION)).not_to be true
      end

      it "deletes a SecurityGroup named \'#{SECURITY_GROUP_NAME}\'" do
        sg_info = AwsWrapper::Ec2::SecurityGroup.find(SECURITY_GROUP_NAME)
        AwsWrapper::Ec2::SecurityGroup.delete(SECURITY_GROUP_NAME)
        created_security_groups.delete(sg_info[:group_id])
        expect(AwsWrapper::Ec2::SecurityGroup.exists?(SECURITY_GROUP_NAME)).not_to be true
      end

      it "add inbound rule referencing itself" do
        sg_info = AwsWrapper::Ec2::SecurityGroup.create(
          SECURITY_GROUP_NAME, DESCRIPTION, VPC_NAME
        )
        created_security_groups << sg_info[:group_id]
        sg = AwsWrapper::Ec2::SecurityGroup.new(SECURITY_GROUP_NAME)
        sg.add_inbound_rule(INBOUND_PROTO_2, INBOUND_PORT_2, INBOUND_SOURCE_2)
        expect(sg.has_inbound_rule?(INBOUND_PROTO_2, INBOUND_PORT_2, INBOUND_SOURCE_2)).to be true
      end

      it "deletes SecurityGroup that has a rule referencing itself" do
        AwsWrapper::Ec2::SecurityGroup.delete!(SECURITY_GROUP_NAME)
        expect(AwsWrapper::Ec2::SecurityGroup.exists?(SECURITY_GROUP_NAME)).not_to be true
      end

      it "associates with network interface" do
        sg_info = AwsWrapper::Ec2::SecurityGroup.create(
          SECURITY_GROUP_NAME, DESCRIPTION, VPC_NAME
        )
        created_security_groups << sg_info[:group_id]
        eni = AwsWrapper::Ec2::NetworkInterface.new(INTERFACE_NAME)
        eni.add_security_group(SECURITY_GROUP_NAME)
        expect(eni.has_security_group?(SECURITY_GROUP_NAME)).to be true
      end

      it "deletes SecurityGroup that associates with network interface" do
        AwsWrapper::Ec2::SecurityGroup.delete!(SECURITY_GROUP_NAME)
        expect(AwsWrapper::Ec2::SecurityGroup.exists?(SECURITY_GROUP_NAME)).not_to be true
      end

      after(:all) do
        created_security_groups.each do |sg_id|
          AwsWrapper::Ec2::SecurityGroup.delete!(sg_id)
        end
        created_interfaces.each do |interface_id|
          AwsWrapper::Ec2::NetworkInterface.delete(interface_id)
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
