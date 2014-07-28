# andschwa-ghost

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - The basics of getting started with andschwa-ghost](#setup)
    * [What andschwa-ghost affects](#what-andschwa-ghost-affects)
    * [Beginning with andschwa-ghost](#beginning-with-andschwa-ghost)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs the Ghost Blogging Platform.

It is in beta development and tested on Ubuntu 12.04 and 14.04,
loosely tested on CentOS.

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

### What andschwa-ghost affects

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

### Beginning with andschwa-ghost

The simplest use of this module is:

```puppet
class { ghost:
  blogs => {
    'my_blog' => {
      'url'  => 'http://my-first-ghost-blog.com',
    }
  }
}
```

### Usage

This module has one main class, `ghost`, with the following
parameters:

```puppet
$user          = 'ghost',
$group         = 'ghost',
$home          = '/home/ghost',
$blogs         = {},   # Hash of blog resources to create
$blog_defaults = {},   # Hash of defaults to apply to blog resources
```

It delegates the user and group resources to `ghost::setup`, which executes
`npm config set registry http://registry.npmjs.org/` to ensure the npm
registry is correctly set (necessary at least on Ubuntu 12.04), and
includes a module to setup nodejs.

Note that Ghost requires an up-to-date nodejs, which can be done
automatically by setting that class's `manage_repo` parameter to true.

The module has one main resource, `ghost::blog`, with the following
parameters:

```puppet
$blog   = $title,                   # Subdirectory and conf name for blog
$home   = "${ghost::home}/${title}", # Root of Ghost instance
$source = 'https://ghost.org/zip/ghost-latest.zip',

# Use [supervisor](http://supervisord.org/) to manage Ghost, with logging
$use_supervisor = true,
$autorestart    = true,
$stdout_logfile = "/var/log/ghost_${title}.log",
$stderr_logfile = "/var/log/ghost_${title}_err.log",

# Parameters below affect Ghost's config through the template
$manage_config = true, # Manage Ghost's config.js

# For a working blog, these must be specified and different per instance
$url    = 'http://my-ghost-blog.com',                  # Required URL of blog
$socket = "${ghost::home}/${title}/production.socket", # Set to false to use host and port
$host   = '127.0.0.1',
$port   = '2368',

# Mail settings (see http://docs.ghost.org/mail/)
$transport    = '', # Mail transport
$fromaddress  = '', # Mail from address
$mail_options = {}, # Hash for mail options
```

These resources can be declared using Hiera by providing a hash to
`ghost::blogs` specifying the blog resources and their parameters,
like this:

```yaml
ghost::blogs:
  blog_one:
    url: http://my-first-ghost-blog.com
    transport: SMTP
	fromaddress: myemail@address.com
	mail_options:
	  auth:
        user: youremail@gmail.com
        pass: yourpassword
  blog_two:
    url: http://my-second-ghost-blog.com
    socket: false
	host: localhost
    port: 2368
```

It is *imperative* that each separate instance has a different URL and
port.

You can disable management of the `config.js` file by setting
`$manage_config` to false.

You can disable the use and setup of `supervisor` by setting
`$use_supervisor` to false.

Note that at least on my Ubuntu test systems, the `supervisor`
module's execution of `supervisorctl update` fails; this can be fixed
by manually running that command, letting it do its thing, and then
re-provisioning.

You will likely want to proxy these using, say, `nginx`. Although the
inclusion of `nginx` is outside the scope of this module, if you are
using the [jfryman/nginx](https://forge.puppetlabs.com/jfryman/nginx)
module, you can declare the virtual hosts to proxy the blogs via Hiera
like so:

```yaml
nginx::nginx_upstreams:
  ghost:
    members:
      - unix:/home/ghost/vagrant/production.socket
nginx::proxy_set_header:
  - Host $host
  - X-Real-IP $remote_addr
  - X-Forwarded-For $proxy_add_x_forwarded_for
  - X-Forwarded-Proto $scheme
nginx::server_tokens: 'off'
nginx::nginx_vhosts:
  ghost:
    use_default_location: false
    rewrite_www_to_non_www: true
    rewrite_to_https: true
nginx::nginx_locations:
  ghost_root:
    vhost: ghost
    location: /
    proxy: http://ghost
    location_cfg_append:
      proxy_ignore_headers: Set-Cookie
      proxy_hide_header: Set-Cookie
```

## Limitations

This module only officially supports Ubuntu, but ought to work with
other operating systems as well.

If managing the blog's `config.js` via this module, you cannot
currently setup Postgres.

If supervisor is not registering the blogs, restarting your system is
the easiest solution (as always), but you should also try
`supervisorctrl reread && supervisorctl reload`.

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
  [puppetlabs/nodejs](https://github.com/puppetlabs/puppetlabs-nodejs/)
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

Fork on [GitHub](https://github.com/andschwa/puppet-ghost), make a
Pull Request.
