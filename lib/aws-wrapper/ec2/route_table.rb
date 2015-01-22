module AwsWrapper
  module Ec2
    class RouteTable

      # RouteTable :id or :name
      def initialize(options)
        @rt = RouteTable.find(options)
        @aws_rt = AWS::EC2::RouteTable.new(@rt[:route_table_id])
      end

      def add_route(cidr, options = {})
        @aws_rt.create_route(cidr, options)
      end

      # If cidr is nil, delete all entries(routes) in the table.
      def delete_route(cidr = nil)
        if cidr.nil?
          routes = @aws_rt.routes
          routes.each do |route|
            @aws_rt.delete_route(route.destination_cidr_block)
          end
        else
          @aws_rt.delete_route(cidr)
        end
      end

      def routes
        @aws_rt.routes
      end

      def has_route?(cidr)
        routes.each do |route|
          return true if route.destination_cidr_block == cidr
        end
        false
      end

      def subnets
        @aws_rt.subnets
      end

      def associations
        @aws_rt.associations
      end

      def associated_with?(options)
        target_subnet = AwsWrapper::Ec2::Subnet.find(options)
        return false if target_subnet.nil?
        subnets.each do |subnet|
          return true if subnet.subnet_id == target_subnet[:subnet_id]
        end
        false
      end

      def vpc
        @aws_rt.vpc
      end

      def delete
        self.delete(:id => @rt[:route_table_id])
      end

      class << self
        # specify vpc by :id or :name
        def create(name, vpc, main = false)
          vpc = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.create_route_table(:vpc_id => vpc[:vpc_id])
          aws_rt = AWS::EC2::RouteTable.new(res[:route_table][:route_table_id])
          aws_rt.add_tag("Name", :value => name)
          find(:id => res[:route_table][:route_table_id])
        end

        def delete(options)
          rt = find(options)
          return false if rt.nil?
          aws_rt = AWS::EC2::RouteTable.new(rt[:route_table_id])
          aws_rt.delete
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          ec2 = AWS::EC2.new
          res = ec2.client.describe_route_tables
          res[:route_table_set].each do |rtable|
            rtable[:tag_set].each do |tag|
              return rtable if options.has_key?(:name) and tag[:value] == options[:name]
            end
            return rtable if options.has_key?(:id) and rtable[:route_table_id] == options[:id]
          end
          nil
        end

        def find_main(vpc_id_or_name)
          vpc = AwsWrapper::Ec2::Vpc.find(vpc_id_or_name)
          return nil if vpc.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.describe_route_tables
          res[:route_table_set].each do |rtable|
            if rtable[:vpc_id] == vpc[:vpc_id]
              rtable[:association_set].each do |association|
                return rtable if association[:main] == true
              end
            end
          end
        end
      end
    end
  end
end
