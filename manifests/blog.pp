define ghost::blog(
  $blog   = $title,                    # Subdirectory and conf name for blog
  $home   = "${ghost::home}/${title}", # Root of Ghost instance
  $source = 'https://ghost.org/zip/ghost-latest.zip',

  # Use [supervisor](http://supervisord.org/) to manage Ghost, with logging
  $use_supervisor = true,
  $autorestart    = true,
  $stdout_logfile = "/var/log/ghost_${title}.log",
  $stderr_logfile = "/var/log/ghost_${title}_err.log",

  # Parameters below affect Ghost's config through the template
  $manage_config = true, # Manage Ghost's config.js

  # For a working blog, these must be specified and different per instance
  $url    = 'http://my-ghost-blog.com',                  # Required URL of blog
  $socket = "${ghost::home}/${title}/production.socket", # Set to false to use host and port
  $host   = '127.0.0.1',
  $port   = '2368',

  # Mail settings (see http://docs.ghost.org/mail/)
  $transport    = '', # Mail transport
  $fromaddress  = '', # Mail from address
  $mail_options = {}, # Hash for mail options
  ) {

  validate_string($blog)
  validate_absolute_path($home)
  validate_string($source)
  validate_bool($use_supervisor)
  validate_bool($autorestart)
  validate_absolute_path($stdout_logfile)
  validate_absolute_path($stderr_logfile)
  validate_bool($manage_config)
  validate_string($url)
  if $socket {
    validate_absolute_path($socket)
  }
  validate_string($host)
  validate_re($port, '\d+')
  validate_string($transport)
  validate_string($fromaddress)
  validate_hash($mail_options)

  include ghost

  Exec {
    cwd     => $home,
    require => File[$home],
  }

  file { $home:
    ensure  => directory,
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
    require     => Exec['npm_config_set_registry'],
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

    supervisor::program { "ghost_${blog}":
      command        => "node ${home}/index.js",
      autorestart    => $autorestart,
      user           => $ghost::user,
      group          => $ghost::group,
      directory      => $home,
      stdout_logfile => $stdout_logfile,
      stderr_logfile => $stderr_logfile,
      environment    => 'NODE_ENV="production"',
    }
  }
}
