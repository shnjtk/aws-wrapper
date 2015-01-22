require "spec_helper"

module AwsWrapper
  module Ec2
    describe SecurityGroup do

      VPC_NAME    = "vpc-securigy-group-test"
      VPC_CIDR    = "10.10.0.0/16"
      SECURITY_GROUP_NAME = "vpc-security-group-test-sg"
      DESCRIPTION = "Security Group for testing"

      created_vpcs = []
      created_security_groups = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc_info = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc_info[:vpc_id]
      end

      it "creates a SecurityGroup named \'#{SECURITY_GROUP_NAME}\'" do
        vpc = AwsWrapper::Ec2::Vpc.find(VPC_NAME)
        sg_info = AwsWrapper::Ec2::SecurityGroup.create(
          SECURITY_GROUP_NAME, DESCRIPTION, vpc[:vpc_id]
        )
        created_security_groups << sg_info[:group_id]
        expect(AwsWrapper::Ec2::SecurityGroup.exists?(SECURITY_GROUP_NAME)).to be true
      end

      it "deletes a SecurityGroup named \'#{SECURITY_GROUP_NAME}\'" do
        sg_info = AwsWrapper::Ec2::SecurityGroup.find(SECURITY_GROUP_NAME)
        AwsWrapper::Ec2::SecurityGroup.delete(SECURITY_GROUP_NAME)
        created_security_groups.delete(sg_info[:group_id])
        expect(AwsWrapper::Ec2::SecurityGroup.exists?(SECURITY_GROUP_NAME)).not_to be true
      end

      after(:all) do
        created_security_groups.each do |sg_id|
          AwsWrapper::Ec2::SecurityGroup.delete(sg_id)
        end
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(vpc_id)
        end
      end

    end
  end
end
