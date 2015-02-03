require 'ipaddr'

module AwsWrapper
  module Ec2
    class SecurityGroup
      PROTO_TCP  = :tcp
      PROTO_UDP  = :udp
      PROTO_ICMP = :icmp
      PROTO_ALL  = :any

      PORT_ALL   = nil

      def initialize(id_or_name)
        @sg = SecurityGroup.find(id_or_name)
        @aws_sg = AWS::EC2::SecurityGroup.new(@sg[:group_id])
      end

      def group_id
        @sg[:group_id]
      end

      def add_inbound_rule(protocol, ports, source)
        return if has_inbound_rule?(protocol, ports, source)
        begin
          @aws_sg.authorize_ingress(protocol, ports, parse_source(source))
        rescue AWS::EC2::Errors::InvalidPermission::Duplicate
        end
      end

      def remove_inbound_rule(protocol, ports, source)
        @aws_sg.revoke_ingress(protocol, ports, parse_source(source))
      end

      def has_inbound_rule?(protocol, ports, source)
        source_hash = create_source_hash(source)
        target_ip_perm = AWS::EC2::SecurityGroup::IpPermission.new(
          @aws_sg, protocol, ports, source_hash
        )
        @aws_sg.ingress_ip_permissions.each do |ip_perm|
          return true if ip_perm.eql?(target_ip_perm)
        end
        false
      end

      def add_outbound_rule(protocol, ports, destination)
        return if has_outbound_rule?(protocol, ports, destination)

        options = { :protocol => protocol, :ports => ports }
        begin
          @aws_sg.authorize_egress(destination, options)
        rescue AWS::EC2::Errors::InvalidPermission::Duplicate
        end
      end

      def remove_outbound_rule(destination)
        @aws_sg.revoke_egress(destination)
      end

      def has_outbound_rule?(protocol, ports, destination)
        destination_hash = create_destination_hash(destination)
        target_ip_perm = AWS::EC2::SecurityGroup::IpPermission.new(
          @aws_sg, protocol, ports, destination_hash
        )
        @aws_sg.egress_ip_permissions.each do |ip_perm|
          return true if ip_perm.eql?(target_ip_perm)
        end
        false
      end

      def parse_source(source)
        if cidr?(source)
          return source
        elsif SecurityGroup.find(source)
          sg = SecurityGroup.find(source)
          return {:group_id => sg[:group_id]}
        elsif AwsWrapper::Elb.find(source)
          elb = AWS::ELB.new.load_balancers[source]
          return elb # AWS::ELB::LoadBalancer
        end
        nil
      end
      private :parse_source

      def create_source_hash(source)
        hash = {}
        hash[:egress] = false
        if cidr?(source)
          hash[:ip_ranges] = [source]
        elsif SecurityGroup.find(source)
          sg = SecurityGroup.new(source)
          hash[:groups] = [AWS::EC2::SecurityGroup.new(sg.group_id)]
        end
        hash
      end

      def create_destination_hash(destination)
        hash = {}
        hash[:egress] = true
        if cidr?(destination)
          hash[:ip_ranges] = [destination]
        elsif SecurityGroup.find(destination)
          sg = SecurityGroup.new(destination)
          hash[:groups] = [AWS::EC2::SecurityGroup.new(sg.group_id)]
        end
        hash
      end

      def cidr?(source)
        begin
          IPAddr.new(source)
          return true
        rescue IPAddr::InvalidAddressError
        end
        false
      end
      private :cidr?

      def disassociate_from_network_interfaces
        vpc = AwsWrapper::Ec2::Vpc.new(@aws_sg.vpc_id)
        vpc.network_interfaces.each do |interface|
          new_groups = []
          interface.security_groups.each do |group|
            new_groups << group.group_id if group.group_id != @aws_sg.group_id
          end
          interface.security_groups = new_groups
        end
      end

      def delete_all_rules
        delete_all_inbound_rules
        delete_all_outbound_rules
      end

      def delete_all_inbound_rules
        @aws_sg.ingress_ip_permissions.each do |ip_perm|
          ip_perm.revoke
        end
      end
      private :delete_all_inbound_rules

      def delete_all_outbound_rules
        @aws_sg.egress_ip_permissions.each do |ip_perm|
          ip_perm.revoke
        end
      end
      private :delete_all_outbound_rules

      class << self
        def create(name, description, vpc)
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.create_security_group(:group_name => name,
                                                 :description => description,
                                                 :vpc_id => vpc_info[:vpc_id])
          find(res[:group_id])
        end

        def delete(id_or_name)
          sg = find(id_or_name)
          return false if sg.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_security_group(:group_id => sg[:group_id])
          res[:return]
        end

        def delete!(id_or_name)
          begin
            delete(id_or_name)
          rescue AWS::EC2::Errors::DependencyViolation
            sg = SecurityGroup.new(id_or_name)
            sg.disassociate_from_network_interfaces
            sg.delete_all_rules
            delete(id_or_name)
          end
        end

        def exists?(id_or_name)
          find(id_or_name).nil? ? false : true
        end

        def find(id_or_name)
          ec2 = AWS::EC2.new
          res = ec2.client.describe_security_groups
          res[:security_group_info].each do |sg|
            return sg if sg[:group_name] == id_or_name
            return sg if sg[:group_id] == id_or_name
          end
          nil
        end
      end
    end
  end
end
