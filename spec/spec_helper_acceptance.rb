require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  if fact_on(host, 'os.family') == 'Debian'
    install_module_from_forge_on(host, 'puppetlabs-apt', '>= 4.1.0 < 5.0.0')
  end
end
