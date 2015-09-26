# Buildserver

Lets you easily compile bash scripts from Ruby to build server instances on your favorite Linux distro.

## Installation

Add this line to your application's Gemfile:

    gem 'buildserver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install buildserver

## Usage

Init a directory like this:

```bash
mkdir -p buildingblocks
touch buildingblocks/build.rb
cat > buildingblocks/build.rb << EOF
require 'buildserver'
require_relative 'blocks/base/builder'

buildserver = Buildserver::Buildserver.new
buildserver.add_role('jumpserver')

buildserver.add_build_block('base', Blocks::Base::Builder.new)

buildserver.build!
EOF

mkdir -p buildingblocks/blocks
mkdir -p buildingblocks/blocks/base
touch buildingblocks/blocks/base/builder.rb
cat > buildingblocks/blocks/base/builder.rb << EOF
require 'buildserver'

module Blocks
  module Base

    class Builder < Buildserver::BuildingBlock
      def build(instance, instances)
        run_command("apt-get update")
        run_command("apt-get -y install aptitude")
        run_command("aptitude -y full-upgrade")

        # Set ssh to only allow keys
        run_command("sed -i \"/#PasswordAuthentication yes/PasswordAuthentication no/g\" /etc/ssh/sshd_config")
        run_command("service ssh restart", :after)
      end

      def external_ports
        [22]
      end
    end

  end
end

EOF
```

### Adding roles:

```ruby
buildserver.add_role('loadbalancer')
buildserver.add_role('utility')
buildserver.add_role('application')
```

### Built-in Builder methods:

#### Templating

To install a template the following is possible:

```ruby
template = template('haproxy.cfg.erb' {port: 80})
install_template(template, "/etc/haproxy/haproxy.cfg")
```

To append a template to a file use `append_template`

```ruby
template = template('pg_hostfile.erb', {username: user.username})
append_template(template, user.username, '/etc/postgresql/9.3/main/pg_hba.conf')
```

#### User existence

To only do something if a user exists on the system:

```ruby
if_user_exists?(@username) do
  # Do stuff
end
```

And if the user don't exists:

```ruby
if_user_dont_exists?(@username) do
  run_command("adduser #{@username} --disabled-password --gecos \"\"")
end
```

#### Directory existence

Use `if_directory_exists?(path)` or `if_directory_dont_exists?(path)`

```ruby
if_directory_exists?("/etc/serf_handlers") do
  template = template('serf_haproxy.rb')
  install_template(template, "/etc/serf_handlers/serf_haproxy.rb")
end

# Installing RBENV
if_directory_dont_exists?("#{@home_dir}/.rbenv") do
  run_command("su #{@username} -c \"cd #{@home_dir} && git clone https://github.com/sstephenson/rbenv.git #{@home_dir}/.rbenv\"")
end
```

#### File existence

Use `if_file_exists?(path)` or `if_file_dont_exists?(path)`

```ruby
if_file_exists?("/etc/nginx/sites-enabled/default") do
  run_command("rm /etc/nginx/sites-enabled/default")
end

if_file_dont_exists?("/sbin/serf") do
  run_command("cd /root")
  run_command("wget https://dl.bintray.com/mitchellh/serf/0.6.2_linux_amd64.zip -O serf.zip")
  run_command("unzip serf.zip")
  run_command("mv serf /sbin/serf")
end
```

### Example of a user builder with login through public-key from Github:

This takes advantage of the fact that Github exposes public-keys for users, you can see mine here: https://github.com/kaspergrubbe.keys

You use this builder like this:

```ruby
require_relative 'blocks/user/builder'
buildserver.add_build_block(:base, Blocks::User::Builder.new('root', {home_dir: '/root', github_users: ['kaspergrubbe']}))
buildserver.add_build_block(:base, Blocks::User::Builder.new('kasper', {github_users: ['kaspergrubbe']}))
```

This is the code:

```ruby
require 'buildserver'

module Blocks
  module User

    class Builder < Buildserver::BuildingBlock
      def initialize(username, options = {})
        @username     = username
        @home_dir     = options.fetch(:home_dir, "/home/#{@username}")
        @github_users = options.fetch(:github_users, [])
      end

      def build(instance, instances)
        if_user_dont_exists?(@username) do
          run_command("  adduser #{@username} --disabled-password --gecos \"\"")
        end

        if !@github_users.nil?
          run_command("touch #{@home_dir}/combined_keys")
          @github_users.each do |github_user|
            run_command("wget https://github.com/#{github_user}.keys -O - >> #{@home_dir}/combined_keys")
            run_command("echo \"\" >> #{@home_dir}/combined_keys")
          end
          run_command("mv #{@home_dir}/combined_keys #{@home_dir}/.ssh/authorized_keys")
          run_command("chown #{@username} #{@home_dir}/.ssh/authorized_keys")
          run_command("chmod 644 #{@home_dir}/.ssh/authorized_keys")
        end

        # Enable color
        run_command("sed -i \"s/#force_color_prompt=yes/force_color_prompt=yes/g\" #{@home_dir}/.bashrc")
      end
    end

  end
end
```

## Contributing

1. Fork it ( https://github.com/Pidrock/buildserver/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
