require 'spec_helper_acceptance'

describe 'ghost class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'works idempotently with no errors' do
      pp = <<-EOS
      class { 'nodejs':
        manage_package_repo => true,
      }
      ->
      class {'ghost':}
      ->
      ghost::blog{ 'my_blog':
        use_supervisor => true,
        socket         => false,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/home/ghost/my_blog') do
      it { should be_directory }
    end

    describe command('ls -al /home/ghost/my_blog') do
      its(:stdout) { should match(/README.md/) }
    end

    context 'Ghost should be running on the default port' do
      describe command('sleep 10 && echo "Give Ghost time to start"') do
        its(:exit_status) { should eq 0 }
      end

      describe command('curl 0.0.0.0:2368/') do
        its(:stdout) { should match %r{Redirecting to https:\/\/my-ghost-blog.com\/} }
      end
    end
  end
end
