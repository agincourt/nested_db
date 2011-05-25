module NestedDb
  module Models
    module Callback
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          cattr_accessor :available_commands
          
          # scopes
          scope :only_before_create, where(:when => 'before', :action => 'create')
          scope :only_after_create,  where(:when => 'after', :action => 'create')
          scope :only_before_update, where(:when => 'before', :action => 'update')
          scope :only_after_update,  where(:when => 'after', :action => 'update')
          scope :only_before_save,   where(:when => 'before', :action => 'save')
          scope :only_after_save,    where(:when => 'after', :action => 'save')
          
          # fields
          field :when
          field :action
          field :command
          
          # associations
          embedded_in :taxonomy,
            :inverse_of => :callbacks,
            :class_name => "NestedDb::Taxonomy"
            
          # validation
          validates_inclusion_of :when,    :in => %w( before after )
          validates_inclusion_of :action,  :in => %w( create update save )
          validate :command_included_in_avaialble_commands, :in => (available_commands || {}).keys
          
          # callback options
          add_available_command(:webhook, NestedDb::Callbacks::WebHook)
        end
      end
      
      module ClassMethods
        def add_available_command(key, klass)
          # ensure the class responds to the run method
          unless klass.respond_to?(:run)
            raise StandardError, "#{klass.name} doesn't respond to :run"
          end
          # ensure the class responds to the run method
          unless klass.respond_to?(:fields)
            raise StandardError, "#{klass.name} doesn't respond to :fields"
          end
          # append fields
          klass.fields.each do |key,options|
            field key, options
          end
          # setup a default hash
          self.available_commands ||= {}
          # merge in the new class
          self.available_commands.merge!(key.to_sym => klass)
        end
      end
      
      module InstanceMethods
        def run(instance)
          callback_class.try(:run, {
            :taxonomy => taxonomy,
            :instance => instance,
            :callback => self
          })
        end
        
        def callback_class
          self.class.available_commands[command.to_sym]
        end
        
        private
        def command_included_in_avaialble_commands
          unless (available_commands || {}).keys.include?(command.try(:to_sym))
            self.errors.add(:command, "is not included in the list (#{(available_commands || {}).keys.join(', ')})")
          end
        end
      end
    end
  end
end