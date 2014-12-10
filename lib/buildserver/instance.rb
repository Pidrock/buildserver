require 'json'

module Buildserver

  class Instance
    attr_reader :hostname, :role, :ip_address, :local_ip_address

    def initialize(hostname, role, ip_address, local_ip_address)
      @hostname         = hostname
      @role             = role.to_s
      @ip_address       = ip_address
      @local_ip_address = local_ip_address
      @build_blocks     = []
    end

    def add_build_block(block)
      @build_blocks << block
    end

    def to_s
      "#{@hostname}/#{@ip_address}/#{@local_ip_address} - #{@role}"
    end

    def services
      @build_blocks.map{|bb| bb.exposes_services}.flatten
    end

    def external_ports
      @build_blocks.map{|bb| bb.external_ports}.flatten
    end

    def internal_ports
      @build_blocks.map{|bb| bb.internal_ports}.flatten
    end

    def has_role?(role)
      @role == role.to_s
    end

    def build(config, instances)
      @commands       = []
      @after_commands = []

      @build_blocks.each do |build_block|
        @commands << "# ! #{build_block.to_s} -------------------------------------"

        commands, after_commands = build_block.build!(config, self, instances)

        @commands << commands
        @commands << "# / #{build_block.to_s} -------------------------------------"

        @after_commands << after_commands
      end

      @commands << @after_commands

      @commands.flatten
    end

  end

end
