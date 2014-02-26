# == Class: ghost
#
# This class installs the Ghost Blogging Platform.
#
# === Examples
#
#  class { ghost:
#    $production_url = 'http://my-ghost-blog.com'
#  }
#
# === Copyright
#
# Copyright 2014 Andrew Schwartzmeyer
#
# === TODO
#
# - add database setup to template
# - add mail setup to template
# - support other operating systems
# - use puppetlabs/nodejs (needs to mature)

class ghost(
  $user             = 'ghost',
  $group            = 'ghost',
  $archive          = '/opt/ghost.zip',
  $source           = 'https://ghost.org/zip/ghost-latest.zip',
  $home             = '/opt/ghost',
  $manage_nodejs    = true, # Install PPA and package
  $use_supervisor   = true, # Use supervisor to manage Ghost
  $autostart        = true, # Supervisor - Start at boot
  $autorestart      = true, # Supervisor - Keep running
  $environment      = 'production', # Supervisor - Ghost config environment to run
  $stdout_logfile   = '/var/log/supervisor/ghost.log',
  $stderr_logfile   = '/var/log/supervisor/ghost_err.log',
  $supervisor_conf  = '/etc/supervisor/conf.d/ghost.conf',

  # Parameters below affect Ghost's config through the template
  $manage_config    = true, # Manage Ghost's config.js
  $development_url  = 'http://my-ghost-blog.com',
  $development_host = '127.0.0.1',
  $development_port = 2368,

  $production_url   = 'http://my-ghost-blog.com',
  $production_host  = '127.0.0.1',
  $production_port  = 2368,
  ) {

  if $ghost::manage_nodejs {
    case $operatingsystem {
      'Ubuntu': {
        ensure_resource(
          'apt::ppa',
          'ppa:chris-lea/node.js',
          { 'before' => 'Package[nodejs]' }
        )
        ensure_resource(
          'package',
          'nodejs',
          { 'before' => 'Exec[npm_install_ghost]' }
        )
      }
      default: {
        fail("${operatingsystem} is not yet supported, please fork and fix (or make an issue).")
      }
    }
  }

  group { $ghost::group:
    ensure => present,
  }

  user { $ghost::user:
    ensure  => present,
    gid     => $ghost::group,
    home    => $ghost::home,
    require => Group[$ghost::group],
  }

  file { $ghost::home:
    ensure => directory,
    owner  => $ghost::user,
    group  => $ghost::group,
  }

  wget::fetch { 'ghost':
    source      => $ghost::source,
    destination => $ghost::archive,
    user        => $ghost::user,
    notify      => Exec['unzip_ghost'],
  }

  ensure_packages(['unzip'])

  exec { 'unzip_ghost':
    command     => "/usr/bin/unzip -uo ${ghost::archive} -d ${ghost::home}",
    user        => $ghost::user,
    require     => [ Package['unzip'], File[$ghost::home] ],
    refreshonly => true,
  }

  exec { 'npm_install_ghost':
    command     => "/usr/bin/npm install --production",
    cwd         => $ghost::home,
    user        => 'root',
    subscribe   => Exec['unzip_ghost'],
    refreshonly => true,
  }

  if $ghost::manage_config {
    file { 'ghost_config':
      path    => "${ghost::home}/config.js",
      owner   => $ghost::user,
      group   => $ghost::group,
      content => template('ghost/config.js.erb'),
      require => Exec['unzip_ghost'],
      notify  => Exec['restart_ghost'],
    }
  }

  if $ghost::use_supervisor {

    ensure_packages(['supervisor'])

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

    exec { 'restart_ghost':
      command => '/usr/bin/supervisorctl restart ghost',
      require => [ Exec['npm_install_ghost'],
                   Service['supervisor'] ],
    }
  }
}
