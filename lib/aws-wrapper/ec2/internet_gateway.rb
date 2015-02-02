module AwsWrapper
  module Ec2
    class InternetGateway

      def initialize(name_or_id)
        @igw = InternetGateway.find(name_or_id)
        @aws_igw = AWS::EC2::InternetGateway.new(@igw[:internet_gateway_id])
      end

      def id
        @aws_igw.id
      end

      class << self
        def create(name, vpc)
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.create_internet_gateway
          igw_id = res[:internet_gateway][:internet_gateway_id]
          igw = AWS::EC2::InternetGateway.new(igw_id)
          igw.add_tag("Name", :value => name)
          igw.attach(vpc_info[:vpc_id])
          find(name)
        end

        def delete(id_or_name)
          igw = find(id_or_name)
          return false if igw.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_internet_gateway(:internet_gateway_id => igw[:internet_gateway_id])
          res[:return]
        end

        def delete!(id_or_name)
          begin
            delete(id_or_name)
          rescue AWS::EC2::Errors::DependencyViolation
            igw = find(id_or_name)
            aws_igw = AWS::EC2::InternetGateway.new(igw[:internet_gateway_id])
            igw[:attachment_set].each do |attachment|
              aws_igw.detach(attachment[:vpc_id])
            end
            delete(id_or_name)
          end
        end

        def exists?(id_or_name)
          find(id_or_name).nil? ? false : true
        end

        def find(id_or_name)
          ec2 = AWS::EC2.new
          res = ec2.client.describe_internet_gateways
          res[:internet_gateway_set].each do |igw|
            igw[:tag_set].each do |tag|
              return igw if tag[:value] == id_or_name
            end
            return igw if igw[:internet_gateway_id] == id_or_name
          end
          nil
        end
      end
    end
  end
end
