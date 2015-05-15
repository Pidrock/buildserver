require 'erb'

module Buildserver
  class BuildingBlock

    def build!(config, instance, other_instances)
      reset!
      @config = config

      build(instance, other_instances)

      [@build_commands, @after_build_commands]
    end

    def exposes_services
      []
    end

    def external_ports
      []
    end

    def internal_ports
      []
    end

   private

    def reset!
      @config               = []
      @build_commands       = []
      @after_build_commands = []
    end

    def run_command(command, direction = :now)
      case direction
      when :after
        @after_build_commands << "    #{command}"
      else
        @build_commands       << "    #{command}"
      end
    end

    ## CONFIG
    ###############################################

    def config(option)
      @config[option]
    end

    ## TEMPLATING
    ###############################################

    def template(filename, vars = {})
      # This is fucking awful :(
      template_path = self.class.to_s.split("::").map(&:downcase).map {|t| t.gsub("builder","templates")}
      pwd = File.join(File.join(Dir.pwd),File.join('buildingblocks'),File.join(template_path),File.join(filename))

      template_file = File.open(pwd)
      rendered_file = ErbTemplate.new.parse(template_file, vars)
      rendered_file
    end

    def install_template(template, location, options = {})
      run_command("touch #{location}")
      run_command("chown #{options.fetch(:owners)} #{location}")     if options.include?(:owners)
      run_command("chmod #{options.fetch(:permission)} #{location}") if options.include?(:permission)

      run_command("cat > #{location} << EOF
#{template}
EOF")
    end

    def append_template(template, splitter, location)
      # Remove old template from file
      run_command("sed -i \"/#---#{splitter.upcase}-START/,/#---#{splitter.upcase}-END/d\" #{location}")

      # Put splitter in beginning and end of template
      new_template =  "#---#{splitter.upcase}-START\n"
      new_template << template
      new_template << "#---#{splitter.upcase}-END\n"

      run_command("cat >> #{location} << EOF
#{new_template}
EOF")
    end

    ## SYSTEM SETUP
    ###############################################

    def if_first_system_setup?(direction = nil)
      run_command("if [ ! -f /root/system_setup_complete ]; then", direction)
      yield if block_given?
      run_command("fi", direction)
    end

    ## USER
    ###############################################

    def if_user_exists?(username)
      run_command("if id -u #{username} >/dev/null 2>&1; then")
      yield if block_given?
      run_command("fi")
    end

    def if_user_dont_exists?(username)
      run_command("if ! id -u #{username} >/dev/null 2>&1; then")
      yield if block_given?
      run_command("fi")
    end

    ## DIRECTORY
    ###############################################

    def if_directory_exists?(path)
      run_command("if [ -d \"#{path}\" ]; then")
      yield if block_given?
      run_command("fi")
    end

    def if_directory_dont_exists?(path)
      run_command("if [ ! -d \"#{path}\" ]; then")
      yield if block_given?
      run_command("fi")
    end

    ## FILES
    ###############################################

    def if_file_exists?(path)
      run_command("if [ -f #{path} ]; then")
      yield if block_given?
      run_command("fi")
    end

    def if_file_dont_exists?(path)
      run_command("if [ ! -f #{path} ]; then")
      yield if block_given?
      run_command("fi")
    end

    ## TEXT EDITING
    ###############################################

    def find_and_replace(before, after, filepath)
      run_command("OLD=\"#{before}\"")
      run_command("NEW=\"#{after}\"")
      run_command("sed -i \"s/\${OLD}/\${NEW}/g\" #{filepath}")
    end

  end
end
