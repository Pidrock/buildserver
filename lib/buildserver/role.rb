require 'json'

module Buildserver

  class Role
    attr_reader :role

    def initialize(role)
      @role         = role.to_s
      @build_blocks = []
    end

    def add_build_block(block)
      @build_blocks << block
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

    def build(roles)
      @commands       = []
      @after_commands = []

      # Safe bash:
      @commands << "set -eux"
      @commands << "set -o pipefail"

      @build_blocks.each do |build_block|
        @commands << "# ! #{build_block.to_s} -------------------------------------"

        commands, after_commands = build_block.build!(self, roles)

        @commands << commands
        @commands << "# / #{build_block.to_s} -------------------------------------"

        @after_commands << after_commands
      end

      @commands << @after_commands

      @commands << "if [ ! -f /root/system_setup_complete ]; then"
      @commands << "echo $(date \"+%Y.%m.%d-%H:%M:%S\") > /root/system_setup_complete"
      @commands << "fi"

      @commands.flatten
    end

  end

end
