class ghost::setup {

  if ! defined(Class['nodejs']) { include nodejs }

  group { $ghost::group:
    ensure => present,
  }

  user { $ghost::user:
    ensure     => present,
    gid        => $ghost::group,
    home       => $ghost::home,
    managehome => true,
    require    => Group[$ghost::group],
  }

  exec { 'npm_config_set_registry':
    command => "npm config set registry ${ghost::npm_registry}",
    unless  => "npm config get registry | grep ${ghost::npm_registry}",
    require => Class['nodejs'],
  }
}
