module AwsWrapper
  module Ec2
    class Acl
      def initialize(options = {})
        @acl = AwsWrapper::Ec2::Acl.find(options)
        @aws_acl = AWS::EC2::NetworkACL.new(@acl[:network_acl_id])
      end
      attr_accessor :aws_acl

      class << self
        def create(name, vpc = {}, options = {})
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          options[:vpc_id] = vpc_info[:vpc_id]
          ec2 = AWS::EC2.new
          res = ec2.client.create_network_acl(options)
          aws_acl = AWS::EC2::NetworkACL.new(res[:network_acl][:network_acl_id])
          aws_acl.add_tag("Name", :value => name)
          find(:name => name)
        end

        def delete(options = {})
          acl = find(options)
          return false if acl.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_network_acl(:network_acl_id => acl[:network_acl_id])
          res[:return]
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          ec2 = AWS::EC2.new
          res = ec2.client.describe_network_acls
          res[:network_acl_set].each do |acl|
            acl[:tag_set].each do |tag|
              return acl if options.has_key?(:name) and tag[:value] == options[:name]
            end
            return acl if options.has_key?(:id) and acl[:network_acl_id] == options[:id]
          end
          nil
        end
      end
    end
  end
end
