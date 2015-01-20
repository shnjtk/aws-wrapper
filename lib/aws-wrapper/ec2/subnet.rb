module AwsWrapper
  module Ec2
    class Subnet
      def initialize(options)
        @subnet = Subnet.find(options)
        @aws_subnet = AWS::EC2::Subnet.new(@subnet[:subnet_id])
      end

      def set_route_table(options = {})
        rt = AwsWrapper::Ec2::RouteTable.find(options)
        return false if rt.nil?
        @aws_subnet.set_route_table(rt[:route_table_id])
      end

      def associated?(options = {})
        rt = AwsWrapper::Ec2::RouteTable.find(options)
        return false if rt.nil?
        @aws_subnet.route_table.route_table_id == rt[:route_table_id]
      end

      class << self
        # specify vpc with :name or :id
        def create(name, cidr, vpc = {}, az = nil)
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          options = {:vpc_id => vpc_info[:vpc_id], :cidr_block => cidr}
          options[:availability_zone] = az unless az.nil?
          res = ec2.client.create_subnet(options)
          aws_subnet = AWS::EC2::Subnet.new(res[:subnet][:subnet_id])
          aws_subnet.add_tag("Name", :value => name)
          find(:name => name) # return subnet
        end

        def delete(options = {})
          subnet = find(options)
          return false if subnet.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_subnet(:subnet_id => subnet[:subnet_id])
          res[:return]
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          ec2 = AWS::EC2.new
          res = ec2.client.describe_subnets
          res[:subnet_set].each do |subnet|
            subnet[:tag_set].each do |tag|
              return subnet if options.has_key?(:name) and tag[:value] == options[:name]
            end
            return subnet if options.has_key?(:id) and subnet[:subnet_id] == options[:id]
          end
          nil
        end
      end
    end
  end
end
