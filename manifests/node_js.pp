class ghost::node_js {

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
      )
    }
    default: {
      fail("${operatingsystem} is not yet supported, please fork and fix (or make an issue).")
    }
  }
}
