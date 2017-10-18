require 'spec_helper'
describe 'ghost::blog', type: :define do
  let :facts do
    {
      osfamily: 'Debian',
      lsbdistid: 'Ubuntu'
    }
  end

  let(:title) { 'my_blog' }

  describe 'defaults' do
    it do
      is_expected.to contain_exec('curl_ghost_my_blog')
    end
    it do
      is_expected.to contain_exec('unzip_ghost_my_blog')
    end
  end
end
