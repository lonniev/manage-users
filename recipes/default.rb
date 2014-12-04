#
# Cookbook Name:: manage-user
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

# remove and create all users of the devops and sysadmin groups
# also for tsusers (who are those with Terminal Server rights)
%w[ devops sysadmin tsusers ].each { |forGroup|

    users_manage forGroup do
        action [ :remove, :create ]
    end
}

# grant passwordless sudo rights to the sysadmin members
node.default['authorization']['sudo']['passwordless'] = true
include_recipe "sudo"

# add several likely SSH hosts with git repositories
ssh_known_hosts_entry 'github.com'
ssh_known_hosts_entry 'bitbucket.org'

# for each user with an has_private_ssh entry, create their ssh identity files
search( "users", "has_private_ssh:true AND NOT action:remove") do |ssh_user|

  ssh_user['username'] ||= ssh_user['id']

  ssh_keys = Chef::EncryptedDataBagItem.load( "private_keys", ssh_user['id'] )

  if ( ssh_keys.empty? )
    
    log "message" do
        message "user #{ssh_user['id']} missing from data_bags/private_keys."
        level :warn
    end
    
    next
  end
  
  sshDir = Pathname.new( ssh_user['home'] ).join( ".ssh" )
  idFile = sshDir.join( "id_rsa" )
  
  directory sshDir.to_s do
    owner ssh_user['username']
    group ssh_user['username']
    mode 0700
    recursive true
    
    action :create
  end

  file sshDir.join( "config" ).to_s do
    owner ssh_user['username']
    group ssh_user['username']
    mode 0600
  
      content <<-EOT
Host *
  StrictHostKeyChecking no
  IdentityFile #{idFile}
  IdentitiesOnly yes
EOT
  end

  file idFile.to_s do
    owner ssh_user['username']
    group ssh_user['username']
    mode 0600
      
    content ssh_keys['private']
  end
  
  file idFile.sub_ext( ".pub" ).to_s do
    owner ssh_user['username']
    group ssh_user['username']
    mode 0644
      
    content ssh_keys['public']
  end
      
end

# for each user with an xsession entry, create their xsession file
search( "users", "xsession:* AND NOT action:remove") do |xs_user|

  xs_user['username'] ||= xs_user['id']
  
  xSessionFile = Pathname.new( xs_user["home"] ).join( .xsession )
  
  file xSessionFile do
      owner xs_user["username"]
      group xs_user["username"]
      mode 0644
      content xs_user["xsession"]
      
      action :create_if_missing
  end
end
