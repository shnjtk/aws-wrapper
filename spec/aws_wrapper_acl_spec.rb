require "spec_helper"

module AwsWrapper
  module Ec2
    describe Acl do

      VPC_NAME = "vpc-acl-test"
      VPC_CIDR = "10.10.0.0/16"
      ACL_NAME = "acl-test"
      SUBNET_NAME = "sn-scl-test"
      SUBNET_CIDR = "10.10.1.0/24"

      INBOUND_NUMBER = 100
      INBOUND_PROTO  = AwsWrapper::Ec2::Acl::PROTO_TCP
      INBOUND_PORT1  = AwsWrapper::Ec2::Acl::PORT_ALL
      INBOUND_PORT2  = (80..80)
      INBOUND_CIDR   = "0.0.0.0/0"
      INBOUND_ACTION = AwsWrapper::Ec2::Acl::ACTION_ALLOW

      OUTBOUND_NUMBER = 100
      OUTBOUND_PROTO  = AwsWrapper::Ec2::Acl::PROTO_TCP
      OUTBOUND_PORT1  = AwsWrapper::Ec2::Acl::PORT_ALL
      OUTBOUND_PORT2  = (80..80)
      OUTBOUND_CIDR   = "0.0.0.0/0"
      OUTBOUND_ACTION = AwsWrapper::Ec2::Acl::ACTION_ALLOW

      created_vpcs = []
      created_acls = []
      created_subnets = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc[:vpc_id]
        subnet = AwsWrapper::Ec2::Subnet.create(SUBNET_NAME, SUBNET_CIDR, VPC_NAME)
        created_subnets << subnet[:subnet_id]
      end

      it "creates Network ACL named '#{ACL_NAME}' in VPC #{VPC_NAME}" do
        acl = AwsWrapper::Ec2::Acl.create(ACL_NAME, VPC_NAME)
        created_acls << acl[:network_acl_id]
        expect(AwsWrapper::Ec2::Acl.exists?(ACL_NAME)).to be true
      end

      it "associates with subnet" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.associate(SUBNET_NAME)
        expect(acl.associated?(SUBNET_NAME)).to be true
      end

      it "disassociates with subnet" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.disassociate(SUBNET_NAME)
        expect(acl.associated?(SUBNET_NAME)).not_to be true
      end

      it "adds the inbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.add_inbound_rule(INBOUND_NUMBER, INBOUND_PROTO, INBOUND_PORT1,
                             INBOUND_CIDR, INBOUND_ACTION)
        expect(acl.inbound_rule_exists?(INBOUND_NUMBER)).to be true
      end

      it "replaces the inbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.add_inbound_rule(INBOUND_NUMBER, INBOUND_PROTO, INBOUND_PORT2,
                             INBOUND_CIDR, INBOUND_ACTION)
        expect(acl.inbound_rule(INBOUND_NUMBER).port_range).to eq(INBOUND_PORT2)
      end

      it "deletes the inbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.delete_inbound_rule(INBOUND_NUMBER)
        expect(acl.inbound_rule_exists?(INBOUND_NUMBER)).not_to be true
      end

      it "adds the outbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.add_outbound_rule(OUTBOUND_NUMBER, OUTBOUND_PROTO, INBOUND_PORT1,
                              OUTBOUND_CIDR, OUTBOUND_ACTION)
        expect(acl.outbound_rule_exists?(OUTBOUND_NUMBER)).to be true
      end

      it "replaces the outbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.add_outbound_rule(OUTBOUND_NUMBER, OUTBOUND_PROTO, OUTBOUND_PORT2,
                              OUTBOUND_CIDR, OUTBOUND_ACTION)
        expect(acl.outbound_rule(OUTBOUND_NUMBER).port_range).to eq(OUTBOUND_PORT2)
      end

      it "deletes the outbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(ACL_NAME)
        acl.delete_outbound_rule(OUTBOUND_NUMBER)
        expect(acl.outbound_rule_exists?(OUTBOUND_NUMBER)).not_to be true
      end

      it "deletes Network ACL named '#{ACL_NAME}'" do
        acl = AwsWrapper::Ec2::Acl.delete(ACL_NAME)
        expect(AwsWrapper::Ec2::Acl.exists?(ACL_NAME)).not_to be true
      end

      after(:all) do
        created_acls.each do |acl_id|
          AwsWrapper::Ec2::Acl.delete(acl_id)
        end
        created_subnets.each do |subnet_id|
          AwsWrapper::Ec2::Subnet.delete(subnet_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(vpc_id)
        end
      end

    end
  end
end
