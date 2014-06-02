class ghost::forever {

  exec { 'npm_install_forever':
    command => 'npm install -g forever',
    onlyif  => 'npm list -g forever',
    user    => 'root',
    require => Package['npm'],
  }
}
