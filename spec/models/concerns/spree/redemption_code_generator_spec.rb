# frozen_string_literal: true

require 'spec_helper'

describe Spree::RedemptionCodeGenerator do
  describe '#generate_redemption_code' do
    subject { described_class.generate_redemption_code }

    it 'generates a 24 character code from unambiguous characters by default' do
      expect(subject).to match(/\A[2-9A-HJKMNP-TV-Z]{24}\z/)
    end

    it 'generates codes of the configured length' do
      stub_spree_preferences(SolidusVirtualGiftCard::Config, redemption_code_length: 8)

      expect(subject).to match(/\A[2-9A-HJKMNP-TV-Z]{8}\z/)
    end
  end

  describe '#format_redemption_code_for_lookup' do
    it 'ignores spaces and other separators typed by people' do
      expect(described_class.format_redemption_code_for_lookup(' k7m2 pq9x ')).to eq 'K7M2PQ9X'
    end

    subject { described_class.format_redemption_code_for_lookup(redemption_code) }

    context 'redemption code has no dashes' do
      let(:redemption_code) { '1234ABCD1234ABCD' }

      it 'does nothing to the code' do
        expect(subject).to eq redemption_code
      end
    end

    context 'redemption code 4 groups of 4 characters, separated by dashes' do
      let(:redemption_code) { '1234-ABCD-1234-ABCD' }
      let(:formatted_redemption_code) { '1234ABCD1234ABCD' }

      it 'strips the dashes' do
        expect(subject).to eq formatted_redemption_code
      end
    end

    context 'redemption code is mixed-case' do
      let(:redemption_code) { '1234-aBCd-1234-AbcD' }
      let(:formatted_redemption_code) { '1234ABCD1234ABCD' }

      it 'makes it all upcase' do
        expect(subject).to eq formatted_redemption_code
      end
    end
  end
end
