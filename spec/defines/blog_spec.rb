# frozen_string_literal: true

require 'spec_helper'

describe 'ghost::blog' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'my_blog' }

      it { is_expected.to contain_exec('curl_ghost_my_blog') }
      it { is_expected.to contain_exec('unzip_ghost_my_blog') }
    end
  end
end
