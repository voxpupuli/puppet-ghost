define ghost::blog(
  $blog             = $title,       # Subdirectory and conf name for blog
  $use_supervisor   = true,         # Use supervisor to manage Ghost
  $autostart        = true,         # Supervisor - Start at boot
  $autorestart      = true,         # Supervisor - Keep running
  $environment      = 'production', # Supervisor - Ghost config environment to run

  # Parameters below affect Ghost's config through the template
  $manage_config    = true, # Manage Ghost's config.js

  # For a working blog, these must be specified and different per instance
  $production_url   = 'http://my-ghost-blog.com',
  $production_host  = '127.0.0.1',
  $production_port  = 2368,

  # These are used when ${environment} is set to 'development'
  $development_url  = 'http://my-ghost-blog.com',
  $development_host = '127.0.0.1',
  $development_port = 2368,

  # Mail settings (see http://docs.ghost.org/mail/)
  $transport        = undef, # Mail transport
  $fromaddress      = undef, # Mail from address
  $mail_options     = {},    # Hash for mail options
  ) {

  include ghost

  validate_string($blog)
  validate_bool($use_supervisor)
  validate_bool($autostart)
  validate_bool($autorestart)
  validate_string($environment)
  validate_bool($manage_config)
  validate_string($production_url)
  validate_string($production_host)
  if !is_integer($production_port) {
    fail('$production_port must be an integer')
  }
  validate_string($development_url)
  validate_string($development_host)
  if !is_integer($development_port) {
    fail('$development_port must be an integer')
  }
  if ($transport != undef) {
    validate_string($transport)
  }
  if ($fromaddress != undef) {
    validate_string($fromaddress)
  }
  validate_hash($mail_options)

  $home = "${ghost::home}/${blog}"

  file { $home:
    ensure => directory,
  }

  ensure_packages(['unzip'])

  exec { "unzip_ghost_${blog}":
    command     => "unzip -uo ${ghost::archive} -d ${home}",
    require     => [ Package['unzip'], File[$home] ],
    subscribe   => Wget::Fetch['ghost'],
    refreshonly => true,
  }

  exec { "npm_install_ghost_${blog}":
    command     => 'npm install --production', # Must be --production
    cwd         => $home,
    user        => 'root',
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
    # Need this file for Exec[restart_ghost] dependency
    file { "ghost_config_${blog}":
      path    => "${home}/restart.lock",
      content => "Puppet: delete this file to force a restart via Puppet"
    }
  }

  if $use_supervisor {

    require ghost::supervisor

    case $operatingsystem {
      'Ubuntu': {
        $stdout_logfile   = "/var/log/supervisor/ghost_${blog}.log"
        $stderr_logfile   = "/var/log/supervisor/ghost_${blog}_err.log"
        $supervisor_conf  = "/etc/supervisor/conf.d/ghost_${blog}.conf"
      }
      default: {
        fail("${operatingsystem} is not yet supported, please fork and fix (or make an issue).")
      }
    }

    file { $supervisor_conf:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('ghost/ghost.conf.erb'),
    }

    exec { "restart_ghost_${blog}":
      command   => "supervisorctl restart ghost_${blog}",
      user      => 'root',
      require   => Exec["npm_install_ghost_${blog}"],
      subscribe => File["ghost_config_${blog}"]
    }
  }
}
