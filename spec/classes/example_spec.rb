require 'spec_helper'

describe 'ghost' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'ghost class without any parameters' do
          let(:params) { {} }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('ghost') }
          it { is_expected.to contain_class('ghost::setup') }
          it { is_expected.to contain_user('ghost') }
          it { is_expected.to contain_group('ghost') }
        end
      end
    end
  end
end
