class ghost::forever {
  package { 'forever':
    ensure   => present,
    provider => 'npm',
  }
}
