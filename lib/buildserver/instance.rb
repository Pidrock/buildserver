require 'json'

module Buildserver

  class Instance
    attr_reader   :hostname, :ip_address, :roles
    attr_accessor :external_ports, :internal_ports

    def initialize(hostname, ip_address, roles = [])
      @hostname   = hostname
      @ip_address = ip_address
      @roles      = roles.map{|role| role.to_s}

      @firewall_commands = []
      @after_commands    = []

      @external_ports    = []
      @internal_ports    = []
    end

    def to_s
      "#{@hostname}/#{@ip_address} - #{@roles}"
    end

    def services
      []
    end

    def has_role?(role)
      @roles.include?(role.to_s)
    end

    def compile(config, instances, blocks)
      commands = []

      blocks.each do |mod|
        build_commands, firewall_commands, after_build_commands = mod.compose(config, self, instances)

        commands           << build_commands
        @firewall_commands << firewall_commands
        @after_commands    << after_build_commands
      end

      commands << compile_firewall
      commands << compile_dna_json
      commands << compile_after_commands

      commands
    end

   private

    def compile_firewall
      firewall_commands = []

      if @firewall_commands.flatten.any?
        firewall_commands << "# ! Firewall -------------------------------------"

        firewall_commands << "  ufw --force enable"
        # firewall_commands << "  while ufw --force delete 1; do"
        # firewall_commands << "    : # no-op"
        # firewall_commands << "  done"

        @firewall_commands.flatten.each do |command|
          firewall_commands << "  #{command}"
        end

        firewall_commands << "# / Firewall -------------------------------------"
      end

      firewall_commands
    end

    def compile_dna_json
      dna_commands = []
      dna_commands << "# ! /etc/dna.json -------------------------------------"

      services = {}
      services['beanstalk'] = {host: 'mjolki.pidrock.com', ip: '127.0.0.1', port: 11300}

      dna_hash = {
        external_ports: self.external_ports,
        internal_ports: self.internal_ports,
      }.to_json

      dna_commands << "touch /etc/dna.json"
      dna_commands << "chmod 744 /etc/dna.json"
      dna_commands << "  cat > /etc/dna.json << EOF
#{dna_hash}
EOF"
      dna_commands << "# ! /etc/dna.json -------------------------------------"
      dna_commands
    end

    def compile_after_commands
      after_commands = []

      if @after_commands.flatten.any?
        after_commands << "# ! After hooks -------------------------------------"

        @after_commands.flatten.each do |command|
          after_commands << "  #{command}"
        end

        after_commands << "# / After hooks -------------------------------------"
      end

      after_commands
    end

  end

end
