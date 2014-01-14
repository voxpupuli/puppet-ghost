# == Class: ghost
#
# Full description of class ghost here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { ghost:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
# TODO
# - add database setup to template
# - add mail setup to template
# - support other operating systems
# - use puppetlabs/nodejs (needs to mature)

class ghost(
  $user             = 'ghost',
  $group            = 'ghost',
  $archive          = '/tmp/ghost.zip',
  $home             = '/opt/ghost',
  $manage_nodejs    = true,
  $autostart        = true,
  $autorestart      = true,
  $environment      = 'production',
  $stdout_logfile   = '/var/log/supervisor/ghost.log',
  $stderr_logfile   = '/var/log/supervisor/ghost_err.log',
  $supervisor_conf  = '/etc/supervisor/conf.d/ghost.conf',

  $development_url  = 'http://my-ghost-blog.com',
  $development_host = '127.0.0.1',
  $development_port = 2368,

  $production_url   = 'http://my-ghost-blog.com',
  $production_host  = '127.0.0.1',
  $production_port  = 2368,
  ) {

  if $manage_nodejs {
    case $operatingsystem {
      'Ubuntu': {
        apt::ppa { 'ppa:chris-lea/node.js':
          before => Package['nodejs'],
        }
        package { 'nodejs':
          ensure => latest,
        }
      }
      default: {}
    }
  }

  group { $ghost::group:
    ensure => present,
  }

  user { $ghost::user:
    ensure     => present,
    gid        => $ghost::group,
    home       => $ghost::home,
    require    => Group[$ghost::group],
  }

  file { $ghost::home:
    ensure => directory,
    owner  => $ghost::user,
    group  => $ghost::group,
  }

  wget::fetch { 'ghost':
    source      => 'https://ghost.org/zip/ghost-latest.zip',
    destination => $ghost::archive,
    before      => Exec['unzip_ghost'],
  }

  package { [ 'unzip', 'supervisor' ]:
    ensure => latest,
  }

  exec { 'unzip_ghost':
    command => "/usr/bin/unzip -uo ${ghost::archive} -d ${ghost::home}",
    user    => $ghost::user,
    require => [ Package['unzip'], File[$ghost::home] ],
  }

  file { 'ghost_config':
    path    => "${ghost::home}/config.js",
    owner   => $ghost::user,
    group   => $ghost::group,
    content => template('ghost/config.js.erb'),
    require => Exec['unzip_ghost'],
    before  => Exec['start_ghost'],
  }

  exec { 'npm_install_ghost':
    command => "/usr/bin/npm install --production",
    cwd     => $ghost::home,
    user    => 'root',
    require => [ Exec['unzip_ghost'], Package['nodejs'] ],
  }

  exec { 'start_ghost':
    command => '/usr/bin/supervisorctl start ghost',
    require => [ Exec['npm_install_ghost'], Service['supervisor'] ],
  }

  file { $ghost::supervisor_conf:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('ghost/ghost.conf.erb'),
    require => Package['supervisor'],
  }

  service { 'supervisor':
    ensure    => running,
    enable    => true,
    require   => Package['supervisor'],
    subscribe => File[$ghost::supervisor_conf],
  }
}
