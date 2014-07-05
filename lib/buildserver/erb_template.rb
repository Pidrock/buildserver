require 'erb'

module Buildserver

  class ErbTemplate
    def initialize
    end

    def parse(template_file, vars)
      template_file.rewind
      template = template_file.read

      vars.each_pair do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end

      ERB.new(template).result(binding)
    end
  end

end
