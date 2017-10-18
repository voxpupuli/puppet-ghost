require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper
install_module
install_module_dependencies

# Soft deps
install_module_from_forge('puppetlabs-apt', '>= 4.1.0 < 5.0.0')

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation
end
