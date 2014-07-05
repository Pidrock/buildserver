require_relative 'buildserver/instance'
require_relative 'buildserver/building_block'
require_relative 'buildserver/erb_template'

module Buildserver

  class Buildserver
    def initialize(config = {})
      @blocks    = {}
      @instances = []

      @config = {}
      @config[:manage_internal_network] = config.fetch(:manage_internal_network, true)
    end

    def load_block(for_role, block)
      @blocks[for_role.to_s] = [] unless @blocks.has_key?(for_role.to_s)
      @blocks[for_role.to_s] << block
    end

    def add_instance(hostname, ip_address, roles = [])
      @instances << Instance.new(hostname, ip_address, roles)
    end

    def build!
      compiled_blocks = {}

      @instances.each do |instance|
        compiled_blocks[instance] = instance.compile(@config, @instances, blocks_for_instance(instance))
      end

      compiled_blocks.each do |instance,commands|
        puts "Writing to #{instance.hostname}.sh..."
        file = File.new("#{instance.hostname}.sh", "w")
        commands.each do |command|
          file.puts(command)
        end
        file.close
      end

      compiled_blocks
    end

  private

    def blocks_for_instance(instance)
      blocks = []
      blocks.concat(@blocks['base'])

      instance.roles.each do |role|
        blocks.concat(@blocks[role]) if @blocks.has_key?(role)
      end

      blocks
    end

  end
end
