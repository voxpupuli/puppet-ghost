class ghost::supervisor {

  ensure_packages(['supervisor'])

  case $::operatingsystem {
    'RedHat', 'CentOS': {
      $supervisor_service = 'supervisord'
    }
    'Ubuntu': {
      $supervisor_service = 'supervisor'
    }
    default: {
      fail("${::operatingsystem} is not yet supported, please fork and fix (or
      make an issue).")
    }
  }
  service { 'supervisor':
    ensure  => running,
    name    => $supervisor_service,
    enable  => true,
    require => Package['supervisor'],
  }
}
