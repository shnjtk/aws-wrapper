module AwsWrapper
  module Ec2
    class NetworkInterface

      attr_reader :aws_interface

      def initialize(id_or_name)
        @interface = AwsWrapper::Ec2::NetworkInterface.find(id_or_name)
        @aws_interface = AWS::EC2::NetworkInterface.new(@interface[:network_interface_id])
      end

      def attachment
        @aws_interface.attachment
      end

      def availability_zone
        @aws_interface.availability_zone
      end

      def elastic_ip
        @aws_interface.elastic_ip
      end

      def instance
        @aws_interface.instance
      end

      def security_groups
        @aws_interface.security_groups
      end

      def subnet
        @aws_interface.subnet
      end

      def vpc
        @aws_interface.vpc
      end

      def attach(instance_id_or_name, device_index = nil)
        instance_info = AwsWrapper::Ec2::Instance.find(instance_id_or_name)
        return false if instance_info.nil?
        options = {}
        options[:device_index] = device_index if device_index
        @aws_interface.attach(instance_info[:instance_id], options)
      end

      def attached?(instance_id_or_name)
        instance_info = AwsWrapper::Ec2::Instance.find(instance_id_or_name)
        return false if instance_info.nil?
        instance.id == instance_info[:instance_id]
      end

      def detach(force_detach = false)
        options = {}
        options[:force] = force_detach
        @aws_interface.detach(options)
      end

      # append security group to the current groups
      def add_security_group(security_group)
        sg_info = AwsWrapper::Ec2::SecurityGroup.find(security_group)
        return false if sg_info.nil?
        security_group_ids = []
        security_groups.each do |sg|
          security_group_ids << sg.id
        end
        security_group_ids << sg_info[:group_id]
        set_security_groups
      end

      def remove_security_group(security_group)
        sg_info = AwsWrapper::Ec2::SecurityGroup.find(security_group)
        security_group_ids = []
        security_groups.each do |group|
          security_group_ids << group.id unless group_id == sg_info[:group_id]
        end
        set_security_group(security_group_ids)
      end

      def set_security_groups(groups = [])
        security_group_ids = []
        groups.each do |group|
          sg_info = AwsWrapper::Ec2::SecurityGroup.find(group)
          security_group_ids << sg_info[:group_id] if sg_info
        end
        @aws_interface.set_security_groups(security_group_ids)
      end

      # security_group :id or :name
      def has_security_group?(security_group)
        sg_info = AwsWrapper::Ec2::SecurityGroup.find(security_group)
        return false if sg_info.nil?
        security_groups.each do |aws_security_group|
          return true if aws_security_group.id == sg_info[:group_id]
        end
        return false
      end

      class << self
        def create(name, subnet, options = {})
          subnet_info = AwsWrapper::Ec2::Subnet.find(subnet)
          return false if subnet_info.nil?
          options[:subnet_id] = subnet_info[:subnet_id]
          ec2 = AWS::EC2.new
          res = ec2.client.create_network_interface(options)
          aws_interface = AWS::EC2::NetworkInterface.new(res[:network_interface][:network_interface_id])
          aws_interface.add_tag("Name", :value => name)
          find(name)
        end

        def delete(id_or_name)
          interface = find(id_or_name)
          return false if interface.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_network_interface(
            :network_interface_id => interface[:network_interface_id]
          )
          res[:return]
        end

        def exists?(id_or_name)
          find(id_or_name).nil? ? false : true
        end

        def find(id_or_name)
          ec2 = AWS::EC2.new
          interfaces = ec2.client.describe_network_interfaces
          interfaces[:network_interface_set].each do |interface|
            interface[:tag_set].each do |tag|
              return interface if tag[:value] == id_or_name
            end
            return interface if interface[:network_interface_id] == id_or_name
          end
          return nil
        end
      end
    end
  end
end
