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
        { 'before' => 'Package[nodejs]' }
      )
      ensure_resource(
        'package',
        'nodejs',
      )
    }
    'RedHat','CentOS': {
      ensure_resource(
        'package',
        'nodejs',
      )
      ensure_resource(
        'package',
        'npm',
      )
    }
    default: {
      fail("${operatingsystem} is not yet supported, please fork and fix (or make an issue).")
    }
  }
}
