require "spec_helper"

module AwsWrapper
  describe InternetGateway do

    VPC_NAME = "vpc-igw-test"
    VPC_CIDR = "10.10.0.0/16"
    IGW_NAME = "igw-test"

    created_vpcs = []
    created_igws = []

    before(:all) do
      AwsWrapper::Core.setup
      vpc_info = AwsWrapper::Vpc.create(VPC_NAME, VPC_CIDR)
      created_vpcs << vpc_info[:vpc_id]
    end

    it "creates a InternetGateway named \'#{IGW_NAME}\'" do
      igw = AwsWrapper::InternetGateway.create(IGW_NAME, {:name => VPC_NAME})
      created_igws << igw[:internet_gateway_id]
      expect(AwsWrapper::InternetGateway.exists?(:name => IGW_NAME)).to be true
    end

    it "deletes a InternetGateway named \'#{IGW_NAME}\'" do
      AwsWrapper::InternetGateway.delete!(:name => IGW_NAME)
      expect(AwsWrapper::InternetGateway.exists?(:name => IGW_NAME)).not_to be true
    end

    after(:all) do
      created_vpcs.each do |vpc_id|
        AwsWrapper::Vpc.delete(:id => vpc_id)
      end
      created_igws.each do |igw_id|
        AwsWrapper::InternetGateway.delete(:id => igw_id)
      end
    end

  end
end
