require "spec_helper"

module AwsWrapper
  describe RouteTable do

    VPC_NAME    = "vpc-rtable-test"
    VPC_CIDR    = "10.10.0.0/16"
    IGW_NAME    = "igw-rtable-test"
    RTABLE_NAME = "rtable-test"
    RTABLE_CIDR = "0.0.0.0/0"

    created_vpcs = []
    created_igws = []
    created_rtables = []

    before(:all) do
      AwsWrapper::Core.setup
      vpc_info = AwsWrapper::Vpc.create(VPC_NAME, VPC_CIDR)
      created_vpcs << vpc_info[:vpc_id]
    end

    it "creates a RouteTable named \'#{RTABLE_NAME}\'" do
      rt_info = AwsWrapper::RouteTable.create(RTABLE_NAME, {:name => VPC_NAME})
      created_rtables << rt_info[:route_table_id]
      expect(AwsWrapper::RouteTable.exists?(:name => RTABLE_NAME)).to be true
    end

    it "deletes a RouteTable named \'#{RTABLE_NAME}\'" do
      AwsWrapper::RouteTable.delete(:name => RTABLE_NAME)
      expect(AwsWrapper::RouteTable.exists?(:name => RTABLE_NAME)).not_to be true
    end

    it "adds an entry to the table" do
      rt_info = AwsWrapper::RouteTable.create(RTABLE_NAME, {:name => VPC_NAME})
      created_rtables << rt_info[:route_table_id]
      rt = AwsWrapper::RouteTable.new(:id => rt_info[:route_table_id])
      igw = AwsWrapper::InternetGateway.create(IGW_NAME, {:name => VPC_NAME})
      created_igws << igw[:internet_gateway_id]
      aws_igw = AWS::EC2::InternetGateway.new(igw[:internet_gateway_id])
      rt.add_route(RTABLE_CIDR, {:internet_gateway => aws_igw})
      expect(rt.has_route?(RTABLE_CIDR)).to be true
    end

    after(:all) do
      created_rtables.each do |rtable_id|
        AwsWrapper::RouteTable.delete(:id => rtable_id)
      end
      created_igws.each do |igw_id|
        AwsWrapper::InternetGateway.delete!(:id => igw_id)
      end
      created_vpcs.each do |vpc_id|
        AwsWrapper::Vpc.delete(:id => vpc_id)
      end
    end

  end
end
