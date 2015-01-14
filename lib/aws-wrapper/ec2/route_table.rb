module AwsWrapper
  class RouteTable
    class << self
      # specify vpc by :id or :name
      def create(name, vpc, rt_entries, main = false)
        vpc = AwsWrapper::Vpc.find(vpc)
        return false if vpc.nil?
        ec2 = AWS::EC2.new
        res = ec2.client.create_route_table(:vpc_id => vpc[:vpc_id])
        aws_rt = AWS::EC2::RouteTable.new(res[:route_table][:route_table_id])
        aws_rt.add_tag("Name", :value => name)
        find(:id => res[:route_table][:route_table_id])
      end

      def delete(options)
        rt = find(options)
        return false if rt.nil?
        aws_rt = AWS::EC2::RouteTable.new(rt[:route_table_id])
        aws_rt.delete
      end

      def exists?(options = {})
        find(options).nil? ? false : true
      end

      def find(options = {})
        ec2 = AWS::EC2.new
        res = ec2.client.describe_route_tables
        res[:route_table_set].each do |rtable|
          rtable[:tag_set].each do |tag|
            return rtable if options.has_key?(:name) and tag[:value] == options[:name]
          end
          return rtable if options.has_key?(:id) and rtable[:route_table_id] == options[:id]
        end
        nil
      end

      def find_main(options = {})
        vpc = AwsWrapper::Vpc.find(options)
        return nil if vpc.nil?
        ec2 = AWS::EC2.new
        res = ec2.client.describe_route_tables
        res[:route_table_set].each do |rtable|
          if rtable[:vpc_id] == vpc[:vpc_id]
            rtable[:association_set].each do |association|
              return rtable if association[:main] == true
            end
          end
        end
      end
    end
  end
end
