require "spec_helper"

module AwsWrapper
  module Ec2
    describe InternetGateway do

      VPC_NAME = "vpc-igw-test"
      VPC_CIDR = "10.10.0.0/16"
      IGW_NAME = "igw-test"

      created_vpcs = []
      created_igws = []

      before(:all) do
        AwsWrapper::Core.setup
        vpc_info = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc_info[:vpc_id]
      end

      it "creates a InternetGateway named \'#{IGW_NAME}\'" do
        igw = AwsWrapper::Ec2::InternetGateway.create(IGW_NAME, VPC_NAME)
        created_igws << igw[:internet_gateway_id]
        expect(AwsWrapper::Ec2::InternetGateway.exists?(IGW_NAME)).to be true
      end

      it "deletes a InternetGateway named \'#{IGW_NAME}\'" do
        AwsWrapper::Ec2::InternetGateway.delete!(IGW_NAME)
        expect(AwsWrapper::Ec2::InternetGateway.exists?(IGW_NAME)).not_to be true
      end

      after(:all) do
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(vpc_id)
        end
        created_igws.each do |igw_id|
          AwsWrapper::Ec2::InternetGateway.delete(igw_id)
        end
      end

    end
  end
end
