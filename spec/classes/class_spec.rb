require 'spec_helper'

describe 'ghost' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('ghost') }
      it { is_expected.to contain_class('ghost::setup') }
      it { is_expected.to contain_user('ghost') }
      it { is_expected.to contain_group('ghost') }
    end
  end
end
