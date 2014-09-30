require 'spec_helper_acceptance'

describe 'ghost class' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      class { 'nodejs':
        manage_repo => true,
      }
      class { ghost:
        blogs => {
          'my_blog' => {
            'url'  => 'http://fooblog.dev',
          }
        }
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_failures => true)
    end
  end
end
