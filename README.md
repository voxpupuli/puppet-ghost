# puppet-ghost [![Build Status](https://travis-ci.org/voxpupuli/puppet-ghost.svg?branch=master)](https://travis-ci.org/voxpupuli/puppet-ghost)

Donated by the excellent [@andschwa](https://twitter.com/andschwa)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - The basics of getting started with ghost](#setup)
    * [What ghost affects](#what-ghost-affects)
    * [Beginning with ghost](#beginning-with-ghost)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs the Ghost Blogging Platform.

It's tested and supported on CentOS/RHEL 6 and 7. Ubuntu 12/14 support got
dropped because those versions are EOL. The module might still be compatible.
Patches for Ubuntu 16/18/20 or other distributions are highly appreciated.

## Module Description

This module is intended for Ubuntu. It essentially follows the
[Linux docs](http://docs.ghost.org/installation/linux/) and
[deployment instructions](http://docs.ghost.org/installation/deploy/)
by using wget to grab the latest Ghost distribution, unzips it, runs
`npm install --production`, configures the config file via a template
(if desired), adds a
[proletaryo/supervisor](https://github.com/proletaryo/puppet-supervisor/)
program to run Ghost, includes
[puppetlabs/nodejs](https://github.com/puppetlabs/puppetlabs-nodejs/)
class, adds the ghost user and group, and finally starts ghost.

## Setup

### What ghost affects

* Packages
  * `nodejs`
  * `npm`
  * `unzip`
  * `curl`
  * `supervisor`
* Services
    * `supervisor`
* Files
    * `/home/ghost/`
    * `/etc/supervisor/conf.d/ghost_<blog>.conf`
* User
    * `ghost`
* Group
    * `ghost`

### Beginning with ghost

The simplest use of this module is:

```puppet
class { 'ghost':
  include_nodejs => true,
} -> ghost::blog { 'my_blog': }
```

#### Ghost Blog Profile

If you just want a working ghost instance, and just want some sensible
defaults and hosted by nginx, you can use the
[ghost_blog_profile](https://github.com/petems/petems-ghost_blog_profile). This
uses this module and sets up a ghost blog to work end-to-end.

```puppet
class { 'ghost_blog_profile::basic':
  blog_name => 'my_blog',
}
```

Here is an alternative Puppet profile for a Ghost blog with Nginx.
```puppet
class profile::ghost {
  include profile::web

  include nodejs

  include ghost
  create_resources('ghost::blog', hiera_hash('ghost::blogs', {}))
}
```

### Usage

This module has one main class, `ghost`, with the following
parameters:

```puppet
$user           = 'ghost',                       # Ghost should run as its own user
$group          = 'ghost',                       # Ghost GID and group to create
$home           = '/home/ghost',                 # Ghost user's home directory, default base for blogs
$include_nodejs = false,                         # Whether or not setup should include nodejs module
```

It delegates the user and group resources to `ghost::setup`, which
creates the user and group you specify (ghost by default) and installs nodejs
and NPM using the puppetlabs-nodejs module.

Ghost requires an up-to-date nodejs, which can be done automatically
by setting that class's `manage_repo` parameter to true. If the
`nodejs` class is not defined elsewhere, this module will simply
include it.

The module has one main resource, `ghost::blog`, with the following
parameters:

```puppet
$user   = 'ghost',                          # Ghost instance should run as its own user
$group  = 'ghost',
$home   = "/home/ghost/${title}",           # Root of Ghost instance (will be created if itdoesnot already exist)
$source = 'https://ghost.org/zip/ghost-latest.zip', # Source for ghost distribution
# The npm registry on some distributions needs to be set
$manage_npm_registry = true,                          # Whether or not to attempt to set thenpmregistry (often needed)
$npm_registry        = 'https://registry.npmjs.org/', # User's npm registry
$use_supervisor = true, # User supervisor module to setup service for blog
$autorestart    = true, # Restart on crash
$stdout_logfile = "/var/log/ghost_${title}.log",
$stderr_logfile = "/var/log/ghost_${title}_err.log",
$manage_config = true, # Manage Ghost's config.js
$url    = 'https://my-ghost-blog.com', # Required URL of blog
$socket = true,                        # Set to false to use host and port
$host   = '127.0.0.1',                 # Host to listen on if not using socket
$port   = '2368',                      # Port of host to listen on
$transport    = '', # Mail transport
$fromaddress  = '', # Mail from address
$mail_options = {}, # Hash for mail options
```

You will likely want to proxy the Ghost instance using, say,
`nginx`. The setup of `nginx` is outside the scope of this module.

## Limitations

* This module only officially supports Ubuntu, but ought to work with
other operating systems as well.

* If managing the blog's `config.js` via this module, you cannot
currently setup custom databases

* The socket file created by Ghost must be readable by the web server
(perhaps Nginx) for communication to take place, but its default
permissions of 660 do not allow this. Because the Ghost server creates
the socket file on each launch, it is impossible to control its
permissions through Puppet. The best solution to this predicament [(see issue #14)](https://github.com/voxpupuli/puppet-ghost/issues/14) is to add your web server's user to Ghost's group (e.g. `usermod -a -G ghost www-data`), which will allow it to read the socket.

## Upgrading from 0.2.x

There are not many changes from 0.2.0 except the following:

* npm registry management is now done in the `ghost::blog` type, and
is controlled by the `npm_registry` parameter
* setting up node using the pupppetlabs-nodejs module is now disabled
by default, and can be enabled by the use of the `manage_nodejs` parameter


## Upgrading from 0.1.x

To upgrade to 0.2.x from 0.1.x, you need to be aware of some major
changes:

- The license has changed from MIT to GNU Affero
- The Ghost source parameter has been moved to `ghost::blog`
- Blog's can have different settings for `home` (root of Ghost)
- The
  [proletaryo/supervisor](https://github.com/proletaryo/puppet-supervisor/)
  module is now used to create a supervisor program in a
  cross-platform manner
- The
  [puppetlabs/nodejs](https://github.com/voxpupuli/puppet-nodejs/)
  module is now used to install nodejs and npm in a cross-platform
  manner
- The 'development' config settings have been removed, in favor of
  setting up only production `url`, `host`, and `port` parameters
- By default, Ghost is now setup to listen on a Unix socket at the
  location of the `socket` parameter (false disables this and falls
  back to host and port)
- For most common uses, the socket file must have 'other' read/write
  permissions, and this is done with an exec because Ghost creates the
  socket file (Puppet is incapable of this)
- Mail parameters `transport`, `fromaddress`, and a `mail_options`
  hash can be specified for each blog
- The `wget` module dependency has been deprecated in favor of a
  simple call to `curl`

## Development

Fork on [GitHub](https://github.com/voxpupuli/puppet-ghost), make a
Pull Request.
