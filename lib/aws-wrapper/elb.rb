module AwsWrapper
  class Elb
    def initialize(name)
      @elb = Elb.find(name)
      @aws_elb = AWS::ELB.new
    end

    def set_health_check(target, interval, timeout, unhealthy_threshold, healthy_threshold)
      options = {}
      options[:load_balancer_name] = @elb.name
      health_check = {}
      health_check[:target] = target
      health_check[:interval] = interval
      health_check[:timeout] = timeout
      health_check[:unhealthy_threshold] = unhealthy_threshold
      health_check[:healthy_threshold] = healthy_threshold
      options[:health_check] = health_check
      @aws_elb.client.configure_health_check(options)
    end

    class << self
      def create(name, listeners, availability_zones = [], subnets = [], security_groups = [], internal = false, tags = [])
        options = {}
        options[:load_balancer_name] = name
        options[:listeners] = listeners
        options[:availability_zones] = availability_zones unless availability_zones.empty?
        subnet_ids = []
        subnets.each do |subnet|
          subnet_ids << AwsWrapper::Ec2::Subnet.find(subnet)[:subnet_id]
        end
        security_group_ids = []
        security_groups.each do |security_group|
          security_group_ids << AwsWrapper::Ec2::SecurityGroup.find(security_group)[:group_id]
        end
        options[:subnets] = subnet_ids unless subnet_ids.empty?
        options[:security_groups] = security_group_ids unless security_group_ids.empty?
        options[:schema] = "internal" if internal
        options[:tags] = tags unless tags.empty?
        aws_elb = AWS::ELB.new
        aws_elb.client.create_load_balancer(options)
      end

      def delete(name)
        aws_elb = AWS::ELB.new
        res = aws_elb.client.delete_load_balancer(:load_balancer_name => name)
        res[:return]
      end

      def delete!(name)
        begin
          delete(name)
        rescue AWS::EC2::Errors::DependencyViolation
          elb = find(name)
          aws_elb = AWS::ELB.new
          aws_elb.client.detach_load_balancer_from_subnets(:load_balancer_name => name,
                                                           :subnets => elb.subnet_ids)
        end
        delete(name)
      end

      def exists?(name)
        find(name).nil? ? false : true
      end

      def find(name)
        aws_elb = AWS::ELB.new
        aws_elb.load_balancers.each do |elb|
          return elb if elb.name == name
        end
        nil
      end

      def create_listener(elb_protocol, elb_port, instance_protocol, instance_port, ssl_cert_id = nil)
        listener = {}
        listener[:protocol] = elb_protocol
        listener[:load_balancer_port] = elb_port
        listener[:instance_protocol] = instance_protocol
        listener[:instance_port] = instance_port
        listener[:ssl_certificate_id] = ssl_cert_id if ssl_cert_id
        listener
      end
    end
  end
end
