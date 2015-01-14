require "spec_helper"

module AwsWrapper
  describe RouteTable do

    VPC_NAME    = "vpc-rtable-test"
    VPC_CIDR    = "10.10.0.0/16"
    RTABLE_NAME = "rtable-test"

    created_vpcs = []
    created_rtables = []

    before(:all) do
      AwsWrapper::Core.setup
      vpc_info = AwsWrapper::Vpc.create(VPC_NAME, VPC_CIDR)
      created_vpcs << vpc_info[:vpc_id]
    end

    it "creates a RouteTable named \'#{RTABLE_NAME}\'" do
      rt = AwsWrapper::RouteTable.create(RTABLE_NAME, {:name => VPC_NAME}, nil)
      created_rtables << rt[:route_table_id]
      expect(AwsWrapper::RouteTable.exists?(:name => RTABLE_NAME)).to be true
    end

    it "deletes a RouteTable named \'#{RTABLE_NAME}\'" do
      AwsWrapper::RouteTable.delete(:name => RTABLE_NAME)
      expect(AwsWrapper::RouteTable.exists?(:name => RTABLE_NAME)).not_to be true
    end

    after(:all) do
      created_rtables.each do |rtable_id|
        AwsWrapper::RouteTable.delete(:id => rtable_id)
      end
      created_vpcs.each do |vpc_id|
        AwsWrapper::Vpc.delete(:id => vpc_id)
      end
    end

  end
end
