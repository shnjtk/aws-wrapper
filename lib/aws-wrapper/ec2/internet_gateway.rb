module AwsWrapper
  module Ec2
    class InternetGateway
      class << self
        # specify vpc with :name or :id
        def create(name, vpc = {})
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.create_internet_gateway
          igw_id = res[:internet_gateway][:internet_gateway_id]
          igw = AWS::EC2::InternetGateway.new(igw_id)
          igw.add_tag("Name", :value => name)
          igw.attach(vpc_info[:vpc_id])
          find(:name => name)
        end

        def delete(options = {})
          igw = find(options)
          return false if igw.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_internet_gateway(:internet_gateway_id => igw[:internet_gateway_id])
          res[:return]
        end

        def delete!(options = {})
          begin
            delete(options)
          rescue AWS::EC2::Errors::DependencyViolation
            igw = find(options)
            aws_igw = AWS::EC2::InternetGateway.new(igw[:internet_gateway_id])
            igw[:attachment_set].each do |attachment|
              aws_igw.detach(attachment[:vpc_id])
            end
            delete(options)
          end
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          ec2 = AWS::EC2.new
          res = ec2.client.describe_internet_gateways
          res[:internet_gateway_set].each do |igw|
            igw[:tag_set].each do |tag|
              return igw if options.has_key?(:name) and tag[:value] == options[:name]
            end
            return igw if options.has_key?(:id) and igw[:internet_gateway_id] == options[:id]
          end
          nil
        end
      end
    end
  end
end
