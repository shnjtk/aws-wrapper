module AwsWrapper
  module Ec2
    class Vpc
      class << self
        def create(name, cidr_block, tenancy = 'default')
          ec2 = AWS::EC2.new
          res = ec2.client.create_vpc(:cidr_block => cidr_block, :instance_tenancy => tenancy)
          aws_vpc = AWS::EC2::VPC.new(res[:vpc][:vpc_id])
          aws_vpc.add_tag("Name", :value => name)
          rt = AwsWrapper::Ec2::RouteTable.find_main(:name => name)
          aws_rt = AWS::EC2::RouteTable.new(rt[:route_table_id])
          aws_rt.add_tag("Name", :value => "#{name}-default")
          find(:name => name) # return vpc
        end

        def delete(options = {})
          vpc = find(options)
          return false if vpc.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_vpc(:vpc_id => vpc[:vpc_id])
          res[:return]
        end

        def delete!(options = {})
          begin
            delete(options)
          rescue AWS::EC2::Errors::DependencyViolation
            vpc = find(options)
            vpc.instances.each do |instance|
              AwsWrapper::Ec2::Instance.delete(:id => instance.id)
            end
            vpc.subnets.each do |subnet|
              AwsWrapper::Ec2::Subnet.delete(:id => subnet.id)
            end
            vpc.route_tables.each do |rtable|
              AwsWrapper::Ec2::RouteTable.delete(:id => rtable.id)
            end
            vpc.security_groups.each do |sg|
              AwsWrapper::Ec2::SecurityGroup.delete(:id => sg.id)
            end
            AwsWrapper::Ec2::InternetGateway.delete(:id => vpc.internet_gateway.id)
            delete(options)
          end
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          ec2 = AWS::EC2.new
          res = ec2.client.describe_vpcs
          res[:vpc_set].each do |vpc|
            vpc[:tag_set].each do |tag|
              return vpc if options.has_key?(:name) and tag[:value] == options[:name]
            end
            return vpc if options.has_key?(:id) and vpc[:vpc_id] == options[:id]
          end
          nil
        end
      end
    end
  end
end
