require 'spec_helper'

module AwsWrapper
  module Ec2
    describe "Version" do
      it 'has a version number' do
        expect(AwsWrapper::VERSION).not_to be nil
      end
    end
  end
end
