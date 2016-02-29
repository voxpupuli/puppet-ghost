require 'spec_helper_acceptance'

describe 'ghost class' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { 'nodejs':
        manage_package_repo => true,
      }
      ->
      class {'ghost':}
      ->
      ghost::blog{ 'my_blog':
        use_supervisor => false,
        socket         => false,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe file('/home/ghost/my_blog') do
      it { should be_directory }
    end

    describe command('ls -al /home/ghost/my_blog') do
      its(:stdout) { should match /README.md/ }
    end
  end
end