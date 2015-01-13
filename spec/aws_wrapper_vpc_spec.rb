require "spec_helper"

module AwsWrapper
  describe Vpc do

    VPC_NAME = "vpc-test"
    VPC_CIDR = "10.10.0.0/16"

    created_vpcs = []

    before(:all) do
      AwsWrapper::Core.setup
    end

    it "confirms a VPC named \'#{VPC_NAME}\' doesn\'t exist" do
      expect(AwsWrapper::Vpc.exists?(:name => VPC_NAME)).not_to be true
    end

    it "creates a VPC named \'#{VPC_NAME}\' with CIDR block \'#{VPC_CIDR}\'" do
      vpc_info = AwsWrapper::Vpc.create(VPC_NAME, VPC_CIDR)
      created_vpcs << vpc_info[:vpc_id]
      expect(AwsWrapper::Vpc.exists?(:name => VPC_NAME)).to be true
    end

    it "has a VPC named \'#{VPC_NAME}\' with CIDR block \'#{VPC_CIDR}\'" do
      vpc_info = AwsWrapper::Vpc.find(:name => VPC_NAME)
      expect(vpc_info).not_to be nil
      expect(vpc_info[:cidr_block]).to eql VPC_CIDR
    end

    it "deletes a VPC named \'#{VPC_NAME}\'" do
      AwsWrapper::Vpc.delete(:name => VPC_NAME)
      expect(AwsWrapper::Vpc.exists?(:name => VPC_NAME)).not_to be true
    end

    after(:all) do
      created_vpcs.each do |vpc_id|
        AwsWrapper::Vpc.delete(:name => vpc_id)
      end
    end

  end
end
