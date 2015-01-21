require "spec_helper"

module AwsWrapper
  module Ec2
    describe Acl do

      VPC_NAME = "vpc-acl-test"
      VPC_CIDR = "10.10.0.0/16"
      ACL_NAME = "acl-test"

      INBOUND_NUMBER = 100
      INBOUND_PROTO  = AwsWrapper::Ec2::Acl::PROTO_TCP
      INBOUND_PORT   = AwsWrapper::Ec2::Acl::PORT_ALL
      INBOUND_CIDR   = "0.0.0.0/0"
      INBOUND_ACTION = AwsWrapper::Ec2::Acl::ACTION_ALLOW

      OUTBOUND_NUMBER = 100
      OUTBOUND_PROTO  = AwsWrapper::Ec2::Acl::PROTO_TCP
      OUTBOUND_PORT   = AwsWrapper::Ec2::Acl::PORT_ALL
      OUTBOUND_CIDR   = "0.0.0.0/0"
      OUTBOUND_ACTION = AwsWrapper::Ec2::Acl::ACTION_ALLOW

      created_vpcs = []
      created_acls = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc[:vpc_id]
      end

      it "creates Network ACL named '#{ACL_NAME}' in VPC #{VPC_NAME}" do
        acl = AwsWrapper::Ec2::Acl.create(ACL_NAME, {:name => VPC_NAME})
        created_acls << acl[:network_acl_id]
        expect(AwsWrapper::Ec2::Acl.exists?(:name => ACL_NAME)).to be true
      end

      it "adds the inbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(:name => ACL_NAME)
        acl.add_inbound_rule(INBOUND_NUMBER, INBOUND_PROTO, INBOUND_PORT,
                             INBOUND_CIDR, INBOUND_ACTION)
        expect(acl.inbound_rule_exists?(INBOUND_NUMBER)).to be true
      end

      it "deletes the inbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(:name => ACL_NAME)
        acl.delete_inbound_rule(INBOUND_NUMBER)
        expect(acl.inbound_rule_exists?(INBOUND_NUMBER)).not_to be true
      end

      it "adds the outbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(:name => ACL_NAME)
        acl.add_outbound_rule(OUTBOUND_NUMBER, OUTBOUND_PROTO, INBOUND_PORT,
                              OUTBOUND_CIDR, OUTBOUND_ACTION)
        expect(acl.outbound_rule_exists?(OUTBOUND_NUMBER)).to be true
      end

      it "deletes the outbound rule" do
        acl = AwsWrapper::Ec2::Acl.new(:name => ACL_NAME)
        acl.delete_outbound_rule(OUTBOUND_NUMBER)
        expect(acl.outbound_rule_exists?(OUTBOUND_NUMBER)).not_to be true
      end

      it "deletes Network ACL named '#{ACL_NAME}'" do
        acl = AwsWrapper::Ec2::Acl.delete(:name => ACL_NAME)
        expect(AwsWrapper::Ec2::Acl.exists?(:name => ACL_NAME)).not_to be true
      end

      after(:all) do
        created_acls.each do |acl_id|
          AwsWrapper::Ec2::Acl.delete(:id => acl_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(:id => vpc_id)
        end
      end

    end
  end
end
