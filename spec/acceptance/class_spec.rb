require 'spec_helper_acceptance'

describe 'ghost class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'works idempotently with no errors' do
      pp = <<-EOS
      class { 'ghost': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe user('ghost') do
      it { is_expected.to exist }
      it { is_expected.to belong_to_group 'ghost' }
    end

    describe group('ghost') do
      it { is_expected.to exist }
    end
  end
end
