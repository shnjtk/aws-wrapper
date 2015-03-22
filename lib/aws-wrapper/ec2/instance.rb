module AwsWrapper
  module Ec2
    class Instance
      WAIT_LIMIT_TIME = 60 # sec
      WAIT_INTERVAL   = 5  # sec

      def initialize(id_or_name)
        @instance = AwsWrapper::Ec2::Instance.find(id_or_name)
        @aws_instance = AWS::EC2::Instance.new(@instance[:instance_id])
      end

      def id
        @aws_instance.id
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

      def attach_network_interface(interface)
        target_eni = AwsWrapper::Ec2::NetworkInterface.new(interface)
        return false if target_eni.nil?
        device_index = 1
        @aws_instance.network_interfaces.each do |attached_interface|
          next if attached_interface.attachment.nil?
          if device_index <= attached_interface.attachment.device_index
            device_index = attached_interface.attachment.device_index + 1
          end
        end
        target_eni.attach(@instance[:instance_id], device_index)
      end

      def detach_network_interface(interface, force = false)
        target_eni = AwsWrapper::Ec2::NetworkInterface.new(interface)
        return false if target_eni.nil?
        target_eni.detach(force)
        sleep 3
      end

      def network_interface_attached?(interface)
        target_eni = AwsWrapper::Ec2::NetworkInterface.new(interface)
        return false if target_eni.nil?
        @aws_instance.network_interfaces.each do |eni|
          return true if eni.id == target_eni.id
        end
        false
      end

      class << self
        def create(name, ami_id, instance_type, options = {})
          options[:image_id] = ami_id
          options[:instance_type] = instance_type
          ec2 = AWS::EC2.new
          aws_instance = ec2.instances.create(options)
          waited_time = 0
          while aws_instance.status != :running and waited_time < WAIT_LIMIT_TIME
            sleep WAIT_INTERVAL
            waited_time = waited_time + WAIT_INTERVAL
          end
          if aws_instance.status != :running
            Instance.delete(aws_instance.id)
            raise AWS::EC2::Errors::IncorrectInstanceState
          end
          aws_instance.add_tag("Name", :value => name)
          find(name)
        end

        def delete(id_or_name)
          instance = find(id_or_name)
          return false if instance.nil?
          aws_instance = AWS::EC2::Instance.new(instance[:instance_id])
          aws_instance.delete
          waited_time = 0
          while aws_instance.status != :shutting_down and waited_time < WAIT_LIMIT_TIME
            sleep WAIT_INTERVAL
            waited_time = waited_time + WAIT_INTERVAL
          end
          if aws_instance.status != :shutting_down
            raise AWS::EC2::Errors::IncorrectInstanceState
          end
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
              next if instance[:instance_state][:name] == "terminated" or
                instance[:instance_state][:name] == "shutting_down"
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
