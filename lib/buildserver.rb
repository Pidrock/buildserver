require 'fileutils'

require_relative 'buildserver/instance'
require_relative 'buildserver/building_block'
require_relative 'buildserver/erb_template'

module Buildserver

  class Buildserver
    def initialize(config = {})
      @instances = []

      @config = config
    end

    def add_instance(hostname, role, ip_address)
      @instances << Instance.new(hostname, role, ip_address)
    end

    def add_build_block(for_role, build_block)
      if for_role == :base
        instances = @instances
      else
        instances = @instances.select{|instance| instance.has_role?(for_role.to_s)}
      end

      instances.each do |instance|
        instance.add_build_block(build_block)
      end
    end

    def build!
      FileUtils.mkdir_p("builds")
      FileUtils.rm( Dir.glob("builds/*") )

      @instances.each do |instance|
        puts "Writing to builds/#{instance.hostname}.sh..."
        commands = instance.build(@config, @instances - [instance])

        file = File.new("builds/#{instance.hostname}.sh", "w")
        commands.each do |command|
          file.puts(command)
        end
        file.close
      end
    end

  end
end
