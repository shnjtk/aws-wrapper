module AwsWrapper
  class Vpc
    class << self
      def create(name, cidr_block, tenancy = 'default')
        ec2 = AWS::EC2.new
        res = ec2.client.create_vpc(:cidr_block => cidr_block, :instance_tenancy => tenancy)
        aws_vpc = AWS::EC2::VPC.new(res[:vpc][:vpc_id])
        aws_vpc.add_tag("Name", :value => name)
        rt = AwsWrapper::RouteTable.find_main(:name => name)
        aws_rt = AWS::EC2::RouteTable.new(rt[:route_table_id])
        aws_rt.add_tag("Name", :value => "#{name}-default")
        find(:name => name) # return vpc
      end

      def delete(options = {})
        vpc = find(options)
        return false if vpc.nil?
        ec2 = AWS::EC2.new
        res = ec2.client.delete_vpc(:vpc_id => vpc[:vpc_id])
        res[:return]
      end

      def exists?(options = {})
        find(options).nil? ? false : true
      end

      def find(options = {})
        ec2 = AWS::EC2.new
        res = ec2.client.describe_vpcs
        res[:vpc_set].each do |vpc|
          vpc[:tag_set].each do |tag|
            return vpc if options.has_key?(:name) and tag[:value] == options[:name]
          end
          return vpc if options.has_key?(:id) and vpc[:vpc_id] == options[:id]
        end
        nil
      end
    end

  end
end
