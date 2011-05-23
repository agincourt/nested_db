require 'digest/sha2'

module NestedDb
  module Encryption
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend ClassMethods
    end
    
    module ClassMethods
      # generates a salt scoped to an object
      def generate_salt
        ::Digest::SHA512.hexdigest("#{Time.now}-#{pepper}-#{rand(1000)}")
      end
      
      # encrypts a password using a salt
      def encrypt(password, salt)
        digest = pepper
        stretches.times { digest = secure_digest(salt, digest, password, pepper) }
        digest
      end
      
      # adds the getters/setters for a password field
      def password_field(name, options = {})
        define_method(name) do
          instance_variable_get(:"@#{name}")
        end
        
        define_method("#{name}=") do |value|
          # store the value in an instance variable
          instance_variable_set(:"@#{name}", value)
          # read the salt
          salt = read_attribute(:"#{name}_salt")
          # if there is no salt
          unless salt
            # generate a salt
            salt = self.class.generate_salt
            # write the salt
            write_attribute(:"#{name}_salt", salt)
          end
          # write the password
          write_attribute(:"encrypted_#{name}", self.class.encrypt(value, salt))
        end
        
        define_method("#{name}_confirmation") do
          instance_variable_get(:"@#{name}_confirmation")
        end
        
        define_method("#{name}_confirmation=") do |value|
          instance_variable_set(:"@#{name}_confirmation", value)
        end
        
        if options[:required]
          validates_presence_of :"#{name}"
        end
      end
      
      private
      # generate a token based on multiple inputs
      def secure_digest(*tokens)
        ::Digest::SHA512.hexdigest('--' << tokens.flatten.join('--') << '--')
      end
      
      # how many times do we repeat the encryption
      def stretches
        10
      end
      
      # a salt scoped to a class - override this in your class (model)
      def pepper
        '1f2e3d+4c5b6a'
      end
    end
    
    module InstanceMethods
      def authenticate(name, password)
        # encrypt the password
        hash = self.class.encrypt(password, send(:"#{name}_salt"))
        # check it matches the stored username/password
        self if hash == send(:"encrypted_#{name}")
      end
    end
  end
end