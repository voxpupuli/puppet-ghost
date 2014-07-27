class ghost::nodejs {

  # Reset file defaults for PPA
  File {
    owner => 'root',
    group => 'root'
  }

  case $::operatingsystem {
    'Ubuntu': {
      ensure_resource(
        'apt::ppa',
        'ppa:chris-lea/node.js',
        { 'before' => '[Package[nodejs], Package[npm]]' }
      )
    }
    default: {}
  }

  ensure_packages(['nodejs', 'npm'])
}
