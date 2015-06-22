FROM ubuntu:14.04
MAINTAINER Andrew Schwartzmeyer <andrew@schwartzmeyer.com>

ADD https://apt.puppetlabs.com/puppetlabs-release-trusty.deb /tmp/
RUN dpkg -i /tmp/puppetlabs-release-trusty.deb
RUN apt-get update && apt-get install -y puppet
RUN puppet --version

COPY pkg/andschwa-ghost-0.3.1.tar.gz /tmp/
RUN puppet module install puppetlabs/stdlib --version 4.6.0
RUN puppet module install puppetlabs/nodejs --version 0.8.0
RUN puppet module install puppetlabs/apt
RUN puppet module install proletaryo/supervisor --version 0.4.0
RUN puppet module install --ignore-dependencies /tmp/andschwa-ghost-0.3.1.tar.gz
RUN puppet apply -e "class { '::nodejs': manage_package_repo => true, npm_package_ensure => 'present' } -> class { 'ghost': } -> ghost::blog { 'my_blog': }"

EXPOSE 2368
