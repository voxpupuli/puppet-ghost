# == Class: ghost::blog
#
# This class sets up a Ghost blog instance. The user and group must
# exist (can be created with the base class), and nodejs and npm must
# be installed.
#
# It will install the latest version of Ghost. Subsequent updates can
# be forced by deleting the archive.
#
# It can also daemonize the Ghost blog instance using supervisor.
#
# === Copyright
#
# Copyright 2014 Andrew Schwartzmeyer
#
# === TODO
#
# - add database setup to template
# - support other operating systems

define ghost::blog(
  String $blog                                   = $title, # Name of blog
  String $user                                   = 'ghost', # Ghost instance should run as its own user
  String $group                                  = 'ghost',
  Stdlib::Absolutepath $home                     = "/home/ghost/${title}",
  # Root of Ghost instance (will be created if it does not already exist)
  Stdlib::HTTPSUrl $source                       = 'https://ghost.org/zip/ghost-latest.zip',
  # Source for ghost distribution

  # The npm registry on some distributions needs to be set
  Boolean $manage_npm_registry                   = true,
  # Whether or not to attempt to set the npm registry (often needed)
  Stdlib::HTTPSUrl $npm_registry                 = 'https://registry.npmjs.org/', # User's npm registry

  # Use [supervisor](http://supervisord.org/) to manage Ghost, with logging
  Boolean $use_supervisor                        = true, # User supervisor module to setup service for blog
  Boolean $autorestart                           = true, # Restart on crash
  Stdlib::Absolutepath $stdout_logfile           = "/var/log/ghost_${title}.log",
  Stdlib::Absolutepath $stderr_logfile           = "/var/log/ghost_${title}_err.log",

  # Parameters below affect Ghost's config through the template
  Boolean $manage_config                         = true, # Manage Ghost's config.js

  # For a working blog, these must be specified and different per instance
  Stdlib::HTTPSUrl $url                          = 'https://my-ghost-blog.com', # Required URL of blog
  String $host                                   = '127.0.0.1', # Host to listen on if not using socket
  Integer $port                                  = 2368, # Port of host to listen on
  Variant[Boolean, Stdlib::Absolutepath] $socket = false, # True will use a socket instead

  # Mail settings (see http://docs.ghost.org/mail/)
  String $transport                              = '', # Mail transport
  String $fromaddress                            = '', # Mail from address
  Hash $mail_options                             = {}, # Hash for mail options
) {

  Exec {
    path    => '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin',
    user    => $user,
    cwd     => $home,
    require => File[$home],
  }

  File {
    owner   => $user,
    group   => $group,
  }

  file { $home:
    ensure  => directory,
  }

  if $manage_npm_registry {
    exec { "npm_config_set_registry_${blog}":
      command => "npm config set registry ${npm_registry}",
      unless  => "npm config get registry | grep ${npm_registry}",
      before  => Exec["npm_install_ghost_${blog}"],
    }
  }

  ensure_packages(['unzip', 'curl'])

  exec { "curl_ghost_${blog}":
    command => "curl -L ${source} -o ghost.zip",
    unless  => 'test -f ghost.zip',
    require => Package['curl'],
  }

  exec { "unzip_ghost_${blog}":
    command     => 'unzip -uo ghost.zip',
    require     => Package['unzip'],
    subscribe   => Exec["curl_ghost_${blog}"],
    refreshonly => true,
  }

  exec { "npm_install_ghost_${blog}":
    command     => 'npm install --production', # Must be --production
    subscribe   => Exec["unzip_ghost_${blog}"],
    refreshonly => true,
  }

  if $manage_config {
    file { "ghost_config_${blog}":
      path    => "${home}/config.js",
      content => template('ghost/config.js.erb'),
      require => Exec["unzip_ghost_${blog}"],
    }
  }
  else {
    # Need this file for Exec[restart_ghost_${blog}] dependency
    file { "ghost_config_${blog}":
      path    => "${home}/puppet.lock",
      content => 'Puppet: delete this file to force a restart via Puppet',
    }
  }

  if $use_supervisor {
    require supervisor

    case $::osfamily {
      'redhat': {
        $path_bin = '/usr/bin'
      }
      'debian': {
        $path_bin = '/usr/local/bin'
      }
      default: {
        fail("ERROR - ${::osfamily} based systems are not supported!")
      }
    }

    Class['supervisor']
    -> supervisor::program { "ghost_${blog}":
      command        => "node ${home}/index.js",
      autorestart    => $autorestart,
      user           => $user,
      group          => $group,
      directory      => $home,
      stdout_logfile => $stdout_logfile,
      stderr_logfile => $stderr_logfile,
      environment    => 'NODE_ENV="production"',
    }

    ~> exec { 'supervisor::update':
      command     => "${path_bin}/supervisorctl reread && ${path_bin}/supervisorctl update",
      user        => 'root',
      group       => 'root',
      logoutput   => on_failure,
      refreshonly => true,
      require     => Service['supervisord'],
    }
  }
}
