require 'fileutils'

require_relative 'buildserver/role'
require_relative 'buildserver/building_block'
require_relative 'buildserver/erb_template'

module Buildserver

  class Buildserver
    def initialize
      @roles = []
    end

    def add_role(role)
      @roles << Role.new(role)
    end

    def add_build_block(for_role, build_block)
      raise ArgumentError.new("Unknown role: #{for_role}") unless (['base'] + @roles.map(&:role)).include?(for_role)

      if for_role == 'base'
        roles = @roles
      else
        roles = @roles.select{|role| role.has_role?(for_role)}
      end

      roles.each do |role|
        role.add_build_block(build_block)
      end
    end

    def build!
      FileUtils.mkdir_p("builds")
      FileUtils.rm( Dir.glob("builds/*") )

      @roles.each do |role|
        puts "Writing to builds/#{role.role}.sh..."
        commands = role.build(@roles - [role])

        file = File.new("builds/#{role.role}.sh", "w")
        commands.each do |command|
          file.puts(command)
        end
        file.close
      end
    end

  end
end
