define ghost::blog(
  $blog        = $title,       # Subdirectory and conf name for blog
  $use_forever = true,         # Use [forever](https://npmjs.org/package/forever) to manage Ghost
  $home        = "${ghost::home}/${blog}", # Root of Ghost instance

  # Parameters below affect Ghost's config through the template
  $manage_config    = true, # Manage Ghost's config.js

  # For a working blog, these must be specified and different per instance
  $url    = 'http://my-ghost-blog.com',  # Required URL of blog
  $socket = "${home}/production.socket", # Set to false to use host and port
  $host   = '127.0.0.1',
  $port   = 2368,

  # Mail settings (see http://docs.ghost.org/mail/)
  $transport        = '', # Mail transport
  $fromaddress      = '', # Mail from address
  $mail_options     = {}, # Hash for mail options
  ) {

  include ghost

  validate_string($blog)
  validate_bool($use_forever)
  validate_absolute_path($home)
  validate_bool($manage_config)
  validate_string($url)
  validate_absolute_path($socket)
  validate_re($host, '\d+\.\d+\.\d+.\d+', )
  validate_re($port, '\d+')
  validate_string($transport)
  validate_string($fromaddress)
  validate_hash($mail_options)

  file { $home:
    ensure => directory,
  }

  ensure_packages(['unzip'])

  exec { "unzip_ghost_${blog}":
    command     => "unzip -uo ${ghost::archive} -d ${home}",
    require     => [ Package['unzip'], File[$home] ],
    subscribe   => Wget::Fetch['ghost'],
    notify      => Exec["npm_install_ghost_${blog}"],
    refreshonly => true,
  }

  exec { "npm_install_ghost_${blog}":
    command     => 'npm install --production', # Must be --production
    cwd         => $home,
    user        => 'root',
    require     => Package['npm'],
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
      content => 'Puppet: delete this file to force a restart via Puppet',
    }
  }

  if $use_forever {

    require ghost::forever

    $logfile        = "/var/log/ghost_forever_${blog}.log"
    $stdout_logfile = "/var/log/ghost_${blog}.log"
    $stderr_logfile = "/var/log/ghost_${blog}_err.log"
    $process        = "${home}/index.js"

    exec { "restart_ghost_${blog}":
      command     => "forever stop ${process} && forever -l ${logfile} -o ${stdout_logfile} -e ${stderr_logfile} start ${process}", # forever returns 0 even on error, so the restart subcommand is not suited to this
      environment => 'NODE_ENV=production',
      user        => 'root',
      require     => Exec['npm_install_forever'],
      subscribe   => [ Exec["npm_install_ghost_${blog}"], File["ghost_config_${blog}"], ],
      refreshonly => true,
    }
  }
}
