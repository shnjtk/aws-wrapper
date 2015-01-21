require "spec_helper"

module AwsWrapper
  module Ec2
    describe Acl do
      VPC_NAME = "vpc-acl-test"
      VPC_CIDR = "10.10.0.0/16"
      ACL_NAME = "acl-test"

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
