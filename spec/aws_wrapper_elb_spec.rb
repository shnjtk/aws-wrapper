require "spec_helper"

module AwsWrapper
  describe Elb do

    VPC_NAME = "vpc-elb-test"
    VPC_CIDR = "10.10.0.0/16"
    IGW_NAME = "igw-elb-test"
    ELB_NAME = "elb-test"
    SUBNET_NAME = "sn-vpc-test"
    SUBNET_CIDR = "10.10.1.0/24"
    SECURITY_GROUP_NAME = "vpc-test-security-group"
    DESCRIPTION = "Security Group for ELB testing"

    created_vpcs = []
    created_igws = []
    created_elbs = []
    created_subnets = []
    created_security_groups = []

    before(:all) do
      AwsWrapper::Core.setup
      vpc_info = AwsWrapper::Vpc.create(VPC_NAME, VPC_CIDR)
      created_vpcs << vpc_info[:vpc_id]
      igw_info = AwsWrapper::InternetGateway.create(IGW_NAME, VPC_NAME)
      created_igws << igw_info[:internet_gateway_id]
      subnet_info = AwsWrapper::Subnet.create(SUBNET_NAME, SUBNET_CIDR, VPC_NAME)
      created_subnets << subnet_info[:subnet_id]
      security_group = AwsWrapper::SecurityGroup.create(SECURITY_GROUP_NAME, DESCRIPTION, vpc_info[:vpc_id])
      created_security_groups << security_group[:group_id]
    end

    it "creates a ELB named \'#{ELB_NAME}\'" do
      listener = AwsWrapper::Elb.create_listener("HTTP", 80, "HTTP", 80)
      vpc = AwsWrapper::Vpc.find(VPC_NAME)
      subnet = AwsWrapper::Subnet.find(SUBNET_NAME)
      sg = AwsWrapper::SecurityGroup.find(SECURITY_GROUP_NAME)
      elb = AwsWrapper::Elb.create(ELB_NAME, [listener], [],
                                  [subnet[:subnet_id]], [sg[:group_id]])
      created_elbs << ELB_NAME
      expect(AwsWrapper::Elb.exists?(ELB_NAME)).to be true
    end

    it "deletes a ELB named \'#{ELB_NAME}\'" do
      AwsWrapper::Elb.delete!(ELB_NAME)
      expect(AwsWrapper::Elb.exists?(ELB_NAME)).not_to be true
    end

    after(:all) do
      created_elbs.each do |elb_name|
        AwsWrapper::Elb.delete!(elb_name)
      end
      created_subnets.each do |subnet_id|
        AwsWrapper::Subnet.delete(subnet_id)
      end
      created_igws.each do |igw_id|
        AwsWrapper::InternetGateway.delete!(igw_id)
      end
      created_vpcs.each do |vpc_id|
        AwsWrapper::Vpc.delete(vpc_id)
      end
    end

  end
end
