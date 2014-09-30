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

    context 'should create the ghost user' do

      describe user('ghost') do
        it { should exist }
      end

      describe group('ghost') do
        it { should exist }
      end
    end

    context 'should create a blog directory called my blog' do
      describe file('/home/ghost/my_blog') do
        it {
          skip 'Live issue right now: Will be fixed with PR #18'
          should be_directory
        }
      end
    end
  end
end
