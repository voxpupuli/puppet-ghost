# ghost::blog
#
# @summary This class sets up a Ghost blog instance.
#
# The user and group must exist (can be created with the base class), and
# nodejs and npm must be installed.
#
# It will install the latest version of Ghost. Subsequent updates can
# be forced by deleting the archive.
#
# It can also daemonize the Ghost blog instance using supervisor.
#
# @param blog Name of blog
# @param user Username for ghost instance to run under
# @param group Group for ghost instance to run under
# @param home Root of Ghost instance (will be created if it does not already exist)
# @param source Source for ghost distribution
# @param manage_npm_registry Whether or not to attempt to set the npm registry (often needed)
# @param npm_registry User's npm registry
# @param use_supervisor Use supervisor module to setup service for blog
# @param autorestart Restart on crash
# @param stdout_logfile Logfile for stdout
# @param stderr_logfile Logfile for stderr
# @param manage_config Manage Ghost's config.js
# @param url Required URL of blog (must be unique)
# @param host Host to listen on if not using socket
# @param port Port to listen on
# @param socket Use a socket instead if true
# @param transport Mail transport
# @param fromaddress Mail from address
# @param mail_options Hash for mail options
#
# Copyright 2014 Andrew Schwartzmeyer
define ghost::blog(
  String $blog                                   = $title,
  String $user                                   = 'ghost',
  String $group                                  = 'ghost',
  Stdlib::Absolutepath $home                     = "/home/ghost/${title}",
  Stdlib::HTTPSUrl $source                       = 'https://ghost.org/zip/ghost-latest.zip',
  Boolean $manage_npm_registry                   = true,
  Stdlib::HTTPSUrl $npm_registry                 = 'https://registry.npmjs.org/',
  Boolean $use_supervisord                       = true, # User supervisor module to setup service for blog
  Boolean $autorestart                           = true, # Restart on crash
  Stdlib::Absolutepath $stdout_logfile           = "/var/log/ghost_${title}.log",
  Stdlib::Absolutepath $stderr_logfile           = "/var/log/ghost_${title}_err.log",
  Boolean $manage_config                         = true,
  Stdlib::HTTPSUrl $url                          = 'https://my-ghost-blog.com',
  String $host                                   = '127.0.0.1',
  Integer $port                                  = 2368,
  Variant[Boolean, Stdlib::Absolutepath] $socket = false,
  String $transport                              = '',
  String $fromaddress                            = '',
  Hash $mail_options                             = {},
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

  if $use_supervisord {
    require supervisord

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

    Class['supervisord']
    -> supervisord::program { "ghost_${blog}":
      command             => "node ${home}/index.js",
      autorestart         => $autorestart,
      user                => $user,
      directory           => $home,
      stdout_logfile      => $stdout_logfile,
      stderr_logfile      => $stderr_logfile,
      program_environment => { 'NODE_ENV' => 'production' },
      notify              => Service['supervisord'],
    }
  }
}
