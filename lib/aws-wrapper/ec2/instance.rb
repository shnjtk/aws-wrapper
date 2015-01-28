module AwsWrapper
  module Ec2
    class Instance
      def initialize(id_or_name)
        @instance = AwsWrapper::Ec2::Instance.find(id_or_name)
        @aws_instance = AWS::EC2::Instance.new(@instance[:instance_id])
      end

      def status
        @aws_instance.status
      end

      def enable_source_dest_check(enabled = true)
        ec2 = AWS::EC2.new
        ec2.client.modify_instance_attribute(
          { :instance_id => @instance[:instance_id], :source_dest_check => { :value => enabled } }
        )
      end

      def source_dest_check
        ec2 = AWS::EC2.new
        res = ec2.client.describe_instance_attribute(
          { :instance_id => @instance[:instance_id], :attribute => "sourceDestCheck"}
        )
        res[:source_dest_check][:value]
      end

      def security_groups
        @aws_instance.security_groups
      end

      def associated_with?(group_id_or_name)
        target_group = AwsWrapper::Ec2::SecurityGroup.find(group_id_or_name)
        @aws_instance.security_groups.each do |group|
          return true if group.group_id == target_group[:group_id]
        end
        return false
      end

      def associate_security_group(group_id_or_name)
        current_groups = []
        security_groups.each { |group| current_groups << group.group_id }
        sg = AwsWrapper::Ec2::SecurityGroup.find(group_id_or_name)
        new_groups = current_groups << sg[:group_id]
        ec2 = AWS::EC2.new
        ec2.client.modify_instance_attribute(
          :instance_id => @instance[:instance_id], :groups => new_groups
        )
      end

      def disassociate_security_group(group_id_or_name)
        current_groups = []
        security_groups.each { |group| current_groups << group.group_id }
        sg = AwsWrapper::Ec2::SecurityGroup.find(group_id_or_name)
        new_groups = current_groups - [ sg[:group_id] ]
        ec2 = AWS::EC2.new
        ec2.client.modify_instance_attribute(
          :instance_id => @instance[:instance_id], :groups => new_groups
        )
      end

      class << self
        def create(name, ami_id, instance_type, options = {})
          options[:image_id] = ami_id
          options[:instance_type] = instance_type
          ec2 = AWS::EC2.new
          aws_instance = ec2.instances.create(options)
          aws_instance.add_tag("Name", :value => name)
          find(name)
        end

        def delete(id_or_name)
          instance = find(id_or_name)
          return false if instance.nil?
          aws_instance = AWS::EC2::Instance.new(instance[:instance_id])
          aws_instance.delete
        end

        def exists?(id_or_name)
          find(id_or_name).nil? ? false : true
        end

        def find(id_or_name)
          ec2 = AWS::EC2.new
          res = ec2.client.describe_instances
          return nil unless res.has_key?(:reservation_set)
          res[:reservation_set].each do |reservation|
            reservation[:instances_set].each do |instance|
              instance[:tag_set].each do |tag|
                return instance if tag[:value] == id_or_name
              end
              return instance if instance[:instance_id] == id_or_name
            end
          end
          nil
        end
      end
    end
  end
end
