require 'spec_helper'

describe Puppet::Type.type(:selinux_state).provider(:selinux_state) do
  let(:resource) do
    Puppet::Type.type(:selinux_state).new(
      name: 'set_selinux_state',
      autorelabel: true,
    )
  end
  let(:provider) do
    Puppet::Type.type(:selinux_state).provider(:selinux_state).new(resource)
  end

  describe 'relabel?' do
    context 'enforcing -> enforcing' do
      it 'does not need relabeling' do
        allow(provider).to receive(:ensure).and_return 'enforcing'
        expect(provider.relabel?('enforcing')).to be_falsey
      end
    end

    context 'enforcing -> permissive' do
      it 'does not need relabeling' do
        allow(provider).to receive(:ensure).and_return 'enforcing'
        expect(provider.relabel?('permissive')).to be_falsey
      end
    end

    context 'enforcing -> disabled' do
      it 'does not need relabeling' do
        allow(provider).to receive(:ensure).and_return 'enforcing'
        expect(provider.relabel?('disabled')).to be_falsey
      end
    end

    context 'permissive -> enforcing' do
      it 'needs relabeling' do
        allow(provider).to receive(:ensure).and_return 'permissive'
        expect(provider.relabel?('enforcing')).to be_truthy
      end
    end

    context 'permissive -> permissive' do
      it 'does not need relabeling' do
        allow(provider).to receive(:ensure).and_return 'permissive'
        expect(provider.relabel?('permissive')).to be_falsey
      end
    end

    context 'permissive -> disabled' do
      it 'does not need relabeling' do
        allow(provider).to receive(:ensure).and_return 'permissive'
        expect(provider.relabel?('disabled')).to be_falsey
      end
    end

    context 'disabled -> enforcing' do
      it 'needs relabeling' do
        allow(provider).to receive(:ensure).and_return 'disabled'
        expect(provider.relabel?('enforcing')).to be_truthy
      end
    end

    context 'disabled -> permissive' do
      it 'needs relabeling' do
        allow(provider).to receive(:ensure).and_return 'disabled'
        expect(provider.relabel?('permissive')).to be_truthy
      end
    end

    context 'disabled -> disabled' do
      it 'does not need relabeling' do
        allow(provider).to receive(:ensure).and_return 'disabled'
        expect(provider.relabel?('disabled')).to be_falsey
      end
    end
  end
end
