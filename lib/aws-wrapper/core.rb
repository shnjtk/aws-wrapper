module AwsWrapper
  module Core
    def self.setup(options = {})
      options[:access_key_id] ||= ENV['AWS_ACCESS_KEY_ID']
      options[:secret_access_key] ||= ENV['AWS_SECRET_ACCESS_KEY']
      options[:region] ||= 'ap-northeast-1'
      options[:ses_region] ||= 'us-east-1'
      AWS.config(
        :access_key_id => options[:access_key_id],
        :secret_access_key => options[:secret_access_key],
        :region => options[:region],
        :ses => { :region => options[:ses_region] }
      )
    end
  end
end
