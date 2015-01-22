require "spec_helper"

module AwsWrapper
  module Ec2
    describe Vpc do

      VPC_NAME = "vpc-test"
      VPC_CIDR = "10.10.0.0/16"

      created_vpcs = []

      before(:all) do
        AwsWrapper::Core.setup
      end

      it "confirms a VPC named \'#{VPC_NAME}\' doesn\'t exist" do
        expect(AwsWrapper::Ec2::Vpc.exists?(VPC_NAME)).not_to be true
      end

      it "creates a VPC named \'#{VPC_NAME}\' with CIDR block \'#{VPC_CIDR}\'" do
        vpc_info = AwsWrapper::Ec2::Vpc.create(VPC_NAME, VPC_CIDR)
        created_vpcs << vpc_info[:vpc_id]
        expect(AwsWrapper::Ec2::Vpc.exists?(VPC_NAME)).to be true
      end

      it "has a VPC named \'#{VPC_NAME}\' with CIDR block \'#{VPC_CIDR}\'" do
        vpc_info = AwsWrapper::Ec2::Vpc.find(VPC_NAME)
        expect(vpc_info).not_to be nil
        expect(vpc_info[:cidr_block]).to eql VPC_CIDR
      end

      it "deletes a VPC named \'#{VPC_NAME}\'" do
        AwsWrapper::Ec2::Vpc.delete(VPC_NAME)
        expect(AwsWrapper::Ec2::Vpc.exists?(VPC_NAME)).not_to be true
      end

      after(:all) do
        created_vpcs.each do |vpc_id|
          AwsWrapper::Ec2::Vpc.delete(vpc_id)
        end
      end

    end
  end
end
