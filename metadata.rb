name             'manage-users'
maintainer       'Lonnie VanZandt'
maintainer_email 'lonniev@gmail.com'
license          'Apache 2.0'
description      'Manages a set of Unix Users from provided Databags'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.1'

depends          'ssh'
depends          'sudo'
depends          'chef-solo-search'
depends          'users'
