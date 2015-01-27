module AwsWrapper
  module Ec2
    class Subnet
      def initialize(id_or_name)
        @subnet = Subnet.find(id_or_name)
        @aws_subnet = AWS::EC2::Subnet.new(@subnet[:subnet_id])
      end

      def set_route_table(id_or_name)
        rt = AwsWrapper::Ec2::RouteTable.find(id_or_name)
        return false if rt.nil?
        @aws_subnet.set_route_table(rt[:route_table_id])
      end

      def associated?(id_or_name)
        rt = AwsWrapper::Ec2::RouteTable.find(id_or_name)
        return false if rt.nil?
        @aws_subnet.route_table.route_table_id == rt[:route_table_id]
      end

      def network_acl
        @aws_subnet.network_acl
      end

      def network_acl=(acl)
        @aws_subnet.network_acl = acl
      end

      def enable_auto_assign_public_ip(enable = true)
        ec2 = AWS::EC2.new
        res = ec2.client.modify_subnet_attribute(
          :subnet_id => @subnet[:subnet_id], :map_public_ip_on_launch => {:value => enable}
        )
        res[:return]
      end

      def auto_assign_public_ip_enabled?
        @subnet[:map_public_ip_on_launch]
      end

      def vpc
        AwsWrapper::Ec2::Vpc.find(@subnet[:vpc_id])
      end

      class << self
        def create(name, cidr, vpc, az = nil, public_ip = false)
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          options = {:vpc_id => vpc_info[:vpc_id], :cidr_block => cidr}
          options[:availability_zone] = az unless az.nil?
          res = ec2.client.create_subnet(options)
          aws_subnet = AWS::EC2::Subnet.new(res[:subnet][:subnet_id])
          aws_subnet.add_tag("Name", :value => name)
          subnet = AwsWrapper::Ec2::Subnet.new(name)
          subnet.enable_auto_assign_public_ip if public_ip
          find(name)
        end

        def delete(id_or_name)
          subnet = find(id_or_name)
          return false if subnet.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_subnet(:subnet_id => subnet[:subnet_id])
          res[:return]
        end

        def delete!(id_or_name)
          begin
            delete(id_or_name)
          rescue AWS::EC2::Errors::DependencyViolation
            subnet = AwsWrapper::Ec2::Subnet.new(id_or_name)
            AwsWrapper::Ec2::Acl.delete(subnet.network_acl.id)
            AwsWrapper::Ec2::RouteTable.delete(subnet.route_table.id)
            subnet.instances.each do |instance|
              AwsWrapper::Ec2::Instance.delete(instance.id)
            end
            delete(id_or_name)
          end
        end

        def exists?(id_or_name)
          find(id_or_name).nil? ? false : true
        end

        def find(id_or_name)
          ec2 = AWS::EC2.new
          res = ec2.client.describe_subnets
          res[:subnet_set].each do |subnet|
            subnet[:tag_set].each do |tag|
              return subnet if tag[:value] == id_or_name
            end
            return subnet if subnet[:subnet_id] == id_or_name
          end
          nil
        end
      end
    end
  end
end
