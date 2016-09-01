#
# Cookbook Name:: manage-users
# Recipe:: default
#
# Copyright 2014, Lonnie VanZandt
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# include the users (empty) recipe to gain the users_manage LWRP
include_recipe "users"

# determine where users' home directories are stored
getHomeCmd = Mixlib::ShellOut.new("useradd -D|grep HOME|cut -d '=' -f 2")
getHomeCmd.run_command

homeDir = getHomeCmd.stdout.chomp

# create any missing home directories
search( "users", "id:* AND NOT action:remove" ) do |usr|

  usr['username'] ||= usr['id']

  usr['home'] = Pathname.new( homeDir ).join( usr['username'] )

  user usr['username'] do
    comment usr['comment']
    home usr['home'].to_s
    shell usr['shell']
    password usr['password']
  end

  directory usr['home'].to_s do
    owner usr['username']
    group usr['username']
    mode 0755
    recursive true
  end

  usr['groups'].each { |grp|

    group grp

    group grp do
      action :modify
      members usr['username']
      append true
      
    end
  }

end

# remove and create all users of the devops and sysadmin groups
# also for tsusers (who are those with Terminal Server rights)
%w[ devops sysadmin tsusers ].each { |forGroup|

    users_manage forGroup do
        action [ :remove, :create ]
    end
}

# grant passwordless sudo rights to the sysadmin members
node.default['authorization']['sudo']['passwordless'] = true
node.default['authorization']['sudo']['include_sudoers_d'] = true
include_recipe "sudo"

# for each user with an has_private_ssh entry, create their ssh identity files
search( "users", "has_private_ssh:true AND NOT action:remove") do |usr|

  usr['username'] ||= usr['id']

  begin

    keys = Chef::EncryptedDataBagItem.load( "private_keys", usr['id'] )

    usr['home'] = Pathname.new( homeDir ).join( usr['username'] )

    sshDir = Pathname.new( usr['home'] ).join( ".ssh" )
    idFile = sshDir.join( "id_rsa" )

    directory sshDir.to_s do
      owner usr['username']
      group usr['username']
      mode 0700
      recursive true

      action :create
    end

    file idFile.to_s do
      owner usr['username']
      group usr['username']
      mode 0600

      content keys['private']

      action :create_if_missing
    end

    file idFile.sub_ext( ".pub" ).to_s do
      owner usr['username']
      group usr['username']
      mode 0644

      content keys['public']

      action :create_if_missing
    end

  rescue Chef::Exceptions::InvalidDataBagPath => e

    log "message" do
      message "missing encrypted data bag 'private_keys' for user #{usr['id']}"
      level :warn
    end

    log "message" do
      message e.message
      level :warn
    end

  rescue JSON::ParserError => e

    log "message" do
      message "malformed encrypted data bag 'private_keys' for user #{usr['id']}"
      level :warn
    end

    log "message" do
      message e.message
      level :warn
    end

  ensure
    next
  end
end

# for each user with an xsession entry, create their xsession file
search( "users", "xsession:* AND NOT action:remove") do |usr|

  usr['username'] ||= usr['id']

  usr['home'] = Pathname.new( homeDir ).join( usr['username'] )

  xSessionFile = Pathname.new( usr["home"] ).join( ".xsession" )

  file xSessionFile.to_s do
      owner usr["username"]
      group usr["username"]
      mode 0644
      content usr["xsession"]

      action :create_if_missing
  end
end
