module AwsWrapper
  module Ec2
    class Instance
      def initialize(options = {})
        @instance = AwsWrapper::Ec2::Instance.find(options)
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
          find(:name => name)
        end

        def delete(options = {})
          instance = find(options)
          return false if instance.nil?
          aws_instance = AWS::EC2::Instance.new(instance[:instance_id])
          aws_instance.delete
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          filters = create_filters(options)
          ec2 = AWS::EC2.new
          res = ec2.client.describe_instances(:filters => filters)
          return nil unless res.has_key?(:reservation_set)
          res[:reservation_set].each do |reservation|
            reservation[:instances_set].each do |instance|
              instance[:tag_set].each do |tag|
                return instance if options.has_key?(:name) and tag[:value] == options[:name]
              end
              return instance if options.has_key?(:id) and instance[:instance_id] == options[:id]
            end
          end
          nil
        end

        def create_filters(options = {})
          filters = []
          if options.has_key?(:id)
            filters << { :name => "instance-id", :values => [ options[:id] ] }
          elsif options.has_key?(:name)
            filters << { :name => "tag:Name", :values => [ options[:name] ] }
          end
          filters
        end
        private :create_filters

      end
    end
  end
end
