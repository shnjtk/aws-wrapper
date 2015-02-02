module AwsWrapper
  module Ec2
    class RouteTable

      def initialize(id_or_name)
        @rt = RouteTable.find(id_or_name)
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

      def associate(subnet_id_or_name)
        target_subnet = AwsWrapper::Ec2::Subnet.new(subnet_id_or_name)
        return false if target_subnet.nil?
        target_subnet.set_route_table(@rt[:route_table_id])
      end

      def disassociate(subnet_id_or_name)
        target_subnet = AwsWrapper::Ec2::Subnet.new(subnet_id_or_name)
        return nil if target_subnet.nil?
        target_subnet.set_route_table(vpc.route_tables.main_route_table.id)
      end

      def associated_with?(subnet_id_or_name)
        target_subnet = AwsWrapper::Ec2::Subnet.find(subnet_id_or_name)
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
        self.delete(@rt[:route_table_id])
      end

      class << self
        def create(name, vpc, main = false)
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.create_route_table(:vpc_id => vpc_info[:vpc_id])
          aws_rt = AWS::EC2::RouteTable.new(res[:route_table][:route_table_id])
          aws_rt.add_tag("Name", :value => name)
          find(res[:route_table][:route_table_id])
        end

        def delete(id_or_name)
          rt = find(id_or_name)
          return false if rt.nil?
          aws_rt = AWS::EC2::RouteTable.new(rt[:route_table_id])
          aws_rt.delete
        end

        def delete!(id_or_name)
          begin
            delete(id_or_name)
          rescue AWS::EC2::Errors::DependencyViolation
            rt = AwsWrapper::Ec2::RouteTable.new(id_or_name)
            rt.associations.each do |assoc|
              assoc.delete unless assoc.main?
            end
            delete(id_or_name)
          end

        end

        def exists?(id_or_name)
          find(id_or_name).nil? ? false : true
        end

        def find(id_or_name)
          ec2 = AWS::EC2.new
          res = ec2.client.describe_route_tables
          res[:route_table_set].each do |rtable|
            rtable[:tag_set].each do |tag|
              return rtable if tag[:value] == id_or_name
            end
            return rtable if rtable[:route_table_id] == id_or_name
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
