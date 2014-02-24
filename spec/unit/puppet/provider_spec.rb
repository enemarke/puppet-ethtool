#!/usr/bin/env rspec
#
require 'spec_helper'

provider_class = Puppet::Type.type(:ethtool).provider(:linux)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:ethtool).new(
      :name => 'eth0',
      :tso => 'enabled',
      :provider => 'linux',
    )
  end

  let(:provider) do
    provider = provider_class.new
    provider.resource = resource
    provider
  end

  def load_fix(type, name)
    provider.expects(:ethtool).with("-#{type}", 'eth0').returns(IO.read("#{File.dirname(__FILE__)}/../../../fixtures/ethtool_outputs/#{type}/#{name}.txt"))
  end

  ['centos5_1', 'ubuntulucid_1'].each do |fixture_name|
    %w{tso ufo gro gso}.each do |type|
      it "can detect #{type} on #{fixture_name}" do
        load_fix('k', fixture_name)
        expect(provider.send(type.to_sym)).to eql('disabled')
      end
    end
  end

  it "can NOT detect lro on centos5_1" do
    load_fix('k', 'centos5_1')
    expect(provider.lro).to eql('unknown')
  end

  it "can detect lro on ubuntulucid_1" do
    load_fix('k', 'ubuntulucid_1')
    expect(provider.lro).to eql('disabled')
  end

  ['centos5_1', 'ubuntulucid_1'].each do |fixture_name|
    %w{sg checksum_rx checksum_tx}.each do |type|
      it "can detect #{type} on #{fixture_name}" do
        load_fix('k', fixture_name)
        expect(provider.send(type.to_sym)).to eql('enabled')
      end
    end
  end

  ['centos5_1', 'ubuntulucid_1'].each do |fixture_name|
    %w{autonegotiate autonegotiate_tx autonegotiate_rx}.each do |type|
      it "can detect #{type} on #{fixture_name}" do
        load_fix('a', fixture_name)
        expect(provider.send(type.to_sym)).to eql(type == 'autonegotiate' ? 'enabled' : 'disabled')
      end
    end
  end

  ['centos5_1', 'ubuntulucid_1'].each do |fixture_name|
    %w{adaptive_tx adaptive_rx}.each do |type|
      it "can detect #{type} on #{fixture_name}" do
        load_fix('c', fixture_name)
        expect(provider.send(type.to_sym)).to eql(type == 'autonegotiate' ? 'enabled' : 'disabled')
      end
    end
  end

  ['centos5_1', 'ubuntulucid_1'].each do |fixture_name|
    %w{rx_usecs rx_frames rx_usecs-irq rx_frames_irq tx_usecs tx_frames tx_usecs_irq tx_frames_irq
       stats_block_usecs pkt_rate_low rx_usecs_low rx_frames_low tx_usecs_low tx_frames_low pkt_rate_high
       rx_usecs_high rx_frames_high tx_usecs_high tx_frames_high sample_interval}.each do |type|
      it "can detect #{type} on #{fixture_name}" do
        load_fix('c', fixture_name)
        expect(provider.send(type.to_sym)).to eql('0')
      end
    end
  end

  it "Be able to enable TSO" do
    provider.expects(:ethtool).with("-K", 'eth0', 'tso', 'on')
    expect { provider.tso = :enabled }.not_to raise_error
  end

  it "Be able to disable TSO" do
    provider.expects(:ethtool).with("-K", 'eth0', 'tso', 'off')
    expect { provider.tso = :disabled }.not_to raise_error
  end

end
