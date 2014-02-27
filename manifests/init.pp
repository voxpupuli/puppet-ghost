# == Class: ghost
#
# This class installs the Ghost Blogging Platform.
#
# It is automatically included when a ghost::blog resource is defined,
# but it can also accept a hash of resources to create.
#
# === Examples
#
# class { ghost:
#   blogs => {
#     # The name, url, and port must be different per instance!
#     'blog_one' => {
#       'production_url'  => 'http://my-first-ghost-blog.com',
#       'production_port' => 2368
#     },
#     'blog_two' => {
#       'production_url' => 'http://my-second-ghost-blog.com',
#       'production_port' => 2369
#     }
#   }
# }
# 
# === Copyright
#
# Copyright 2014 Andrew Schwartzmeyer
#
# === TODO
#
# - add database setup to template
# - add mail setup to template
# - support other operating systems
# - use puppetlabs/nodejs (needs to mature)

class ghost(
  $user             = 'ghost',
  $group            = 'ghost',
  $home             = '/opt/ghost',
  $archive          = "${home}/ghost.zip",
  $source           = 'https://ghost.org/zip/ghost-latest.zip',
  $manage_nodejs    = true, # Install PPA and package
  $blogs            = {},   # Hash of blog resources to create
  $blog_defaults    = {},   # Hash of defaults to apply to blog resources
  ) {

  # resource defaults
  Exec {
    path => '/usr/bin:/bin:/usr/sbin:/sbin',
    user => $user,
  }

  File {
    owner => $user,
    group => $group,
  }

  include ghost::setup

  if $manage_nodejs {
    require ghost::node_js
  }

  create_resources('ghost::blog', $blogs, $blog_defaults)

}
