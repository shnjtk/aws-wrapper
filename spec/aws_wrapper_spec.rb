require 'spec_helper'

module AwsWrapper
  describe "Version" do
    it 'has a version number' do
      expect(AwsWrapper::VERSION).not_to be nil
    end
  end
end
