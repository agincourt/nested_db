module NestedDb
  module Callbacks
    class WebHook < Base
      # set our reference
      reference :webhook
      
      configure do
        # fields
        field :web_hook_url
        # validation
        validates_presence_of :web_hook_url,
          :if => proc { |obj| 'webhook' == obj.command }
      end
      
      # runs the callback
      def run
        return true unless Rails.env.production?
        Net::HTTP.post_form(URI.parse(callback.web_hook_url), instance.serializable_hash)
      end
    end
  end
end