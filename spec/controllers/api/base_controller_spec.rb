require "rails_helper"

RSpec.describe Api::BaseController do
  %i[event_namespace internal_server_error_body too_many_requests_body].each do |hook|
    it "requires subclasses to implement ##{hook}" do
      expect { described_class.new.send(hook) }.to raise_error(NotImplementedError)
    end
  end
end
