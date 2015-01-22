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
