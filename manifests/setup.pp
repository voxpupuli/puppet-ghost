class ghost::setup {

  include nodejs

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
    command => 'npm config set registry http://registry.npmjs.org/',
    require => Class['nodejs'],
  }
}
