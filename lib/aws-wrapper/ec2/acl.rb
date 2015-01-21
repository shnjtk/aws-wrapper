module AwsWrapper
  module Ec2
    class Acl

      ACTION_ALLOW = :allow
      ACTION_DENY  = :deny

      PROTO_TCP = 6
      PROTO_UDP = 17
      PROTO_ALL = -1

      PORT_ALL = (1..65535)

      def initialize(options = {})
        @acl = AwsWrapper::Ec2::Acl.find(options)
        @aws_acl = AWS::EC2::NetworkACL.new(@acl[:network_acl_id])
      end

      def subnets
        @aws_acl.subnets
      end

      def inbound_rules
        rules = []
        @aws_acl.entries.each do |entry|
          rules << entry unless entry.egress
        end
        rules
      end

      def inbound_rule_exists?(number)
        rule_exists?(number, false)
      end

      def add_inbound_rule(number, protocol, port_range, cidr, action, options = {})
        if rule_exists?(number, false)
          replace_entry(number, protocol, port_range, cidr, action, false, options)
        else
          create_entry(number, protocol, port_range, cidr, action, false, options)
        end
      end

      def delete_inbound_rule(number)
        delete_entry(:ingress, number)
      end

      def outbound_rules
        rules = []
        @aws_acl.entries.each do |entry|
          rules << entry if entry.egress
        end
        rules
      end

      def outbound_rule_exists?(number)
        rule_exists?(number, true)
      end

      def add_outbound_rule(number, protocol, port_range, cidr, action, options = {})
        if rule_exists?(number, true)
          replace_entry(number, protocol, port_range, cidr, action, true, options)
        else
          create_entry(number, protocol, port_range, cidr, action, true, options)
        end
      end

      def delete_outbound_rule(number)
        delete_entry(:egress, number)
      end

      def create_entry(number, protocol, port_range, cidr, action, egress, options = {})
        options[:rule_number] = number
        options[:action] = action
        options[:protocol] = protocol
        options[:cidr_block] = cidr
        options[:egress] = egress
        options[:port_range] = port_range
        @aws_acl.create_entry(options)
      end
      private :create_entry

      def delete_entry(egress_or_ingress, number)
        @aws_acl.delete_entry(egress_or_ingress, number)
      end
      private :delete_entry

      def replace_entry(number, protocol, port_range, cidr, action, egress, options = {})
        options[:rule_number] = number
        options[:action] = action
        options[:protocol] = protocol
        options[:cidr_block] = cidr
        options[:egress] = egress
        options[:port_range] = port_range
        @aws_acl.replace_entry(options)
      end
      private :replace_entry

      def rule_exists?(number, egress = false)
        rules = egress ? outbound_rules : inbound_rules
        rules.each do |rule|
          return true if rule.rule_number == number
        end
        false
      end
      private :rule_exists?

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