require "spec_helper"

module AwsWrapper
  describe SecurityGroup do

    VPC_NAME    = "vpc-securigy-group-test"
    VPC_CIDR    = "10.10.0.0/16"
    SECURITY_GROUP_NAME = "vpc-security-group-test-sg"
    DESCRIPTION = "Security Group for testing"

    created_vpcs = []
    created_security_groups = []

    before(:all) do
      AwsWrapper::Core.setup
      vpc_info = AwsWrapper::Vpc.create(VPC_NAME, VPC_CIDR)
      created_vpcs << vpc_info[:vpc_id]
    end

    it "creates a SecurityGroup named \'#{SECURITY_GROUP_NAME}\'" do
      vpc = AwsWrapper::Vpc.find(:name => VPC_NAME)
      sg_info = AwsWrapper::SecurityGroup.create(SECURITY_GROUP_NAME,
                                                 DESCRIPTION,
                                                 {:id => vpc[:vpc_id]})
      created_security_groups << sg_info[:group_id]
      expect(AwsWrapper::SecurityGroup.exists?(:name => SECURITY_GROUP_NAME)).to be true
    end

    it "deletes a SecurityGroup named \'#{SECURITY_GROUP_NAME}\'" do
      sg_info = AwsWrapper::SecurityGroup.find(:name => SECURITY_GROUP_NAME)
      AwsWrapper::SecurityGroup.delete(:name => SECURITY_GROUP_NAME)
      created_security_groups.delete(sg_info[:group_id])
      expect(AwsWrapper::SecurityGroup.exists?(:name => SECURITY_GROUP_NAME)).not_to be true
    end

    after(:all) do
      created_security_groups.each do |sg_id|
        AwsWrapper::SecurityGroup.delete(:id => sg_id)
      end
      created_vpcs.each do |vpc_id|
        AwsWrapper::Vpc.delete(:id => vpc_id)
      end
    end

  end
end
