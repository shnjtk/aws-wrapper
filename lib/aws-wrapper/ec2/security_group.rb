module AwsWrapper
  module Ec2
    class SecurityGroup
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
