module Liquid
  class Assign < Tag
    Syntax = /(#{VariableSignature}+)\s*=\s*([^=]+)/
  end
end