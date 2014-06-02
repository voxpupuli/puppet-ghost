class ghost::forever {

  Exec {
    user => 'root',
  }

  ensure_packages(['g++'])

  case $::operatingsystem {
    'Ubuntu': {

      exec { 'npm_config_set_registry':
        command => 'npm config set registry http://registry.npmjs.org/',
        before  => Exec['npm_install_forever'],
      }
    }

    default: {}
  }

  exec { 'npm_install_forever':
    command => 'npm install -g forever',
    onlyif  => 'npm list -g forever',
    require => [Package['npm'], Package['g++']],
  }
}
