module AwsWrapper
  module Ec2
    class SecurityGroup
      class << self
        # specify vpc by :id or :name
        def create(name, description, vpc = {})
          vpc_info = AwsWrapper::Ec2::Vpc.find(vpc)
          return false if vpc_info.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.create_security_group(:group_name => name,
                                                 :description => description,
                                                 :vpc_id => vpc_info[:vpc_id])
          find(:id => res[:group_id])
        end

        def delete(options = {})
          sg = find(options)
          return false if sg.nil?
          ec2 = AWS::EC2.new
          res = ec2.client.delete_security_group(:group_id => sg[:group_id])
          res[:return]
        end

        def exists?(options = {})
          find(options).nil? ? false : true
        end

        def find(options = {})
          ec2 = AWS::EC2.new
          res = ec2.client.describe_security_groups
          res[:security_group_info].each do |sg|
            return sg if options.has_key?(:name) and sg[:group_name] == options[:name]
            return sg if options.has_key?(:id) and sg[:group_id] == options[:id]
          end
          nil
        end
      end
    end
  end
end
