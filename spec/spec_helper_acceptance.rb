# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  install_module_from_forge_on(host, 'puppetlabs-apt', '>= 4.1.0 < 9.0.0') if fact_on(host, 'os.family') == 'Debian'
end
