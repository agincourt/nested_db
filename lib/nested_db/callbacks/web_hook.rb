module NestedDb
  module Callbacks
    class WebHook < Base
      # defines custom fields
      def self.fields
        super.merge({
          :web_hook_url => {
            :type     => String,
            :required => proc { |obj| 'webhook' == obj.command }
          }
        })
      end
      
      # runs the callback
      def run
        return true unless Rails.env.production?
        Net::HTTP.post_form(URI.parse(callback.web_hook_url), instance.serializable_hash)
      end
    end
  end
end