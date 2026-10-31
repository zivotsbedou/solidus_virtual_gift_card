# frozen_string_literal: true

require 'spec_helper'

describe Spree::GiftCardMailer, type: :mailer do
  describe '#gift_card_email' do
    subject { described_class.gift_card_email(gift_card) }

    let(:gift_card) { create(:redeemable_virtual_gift_card) }

    context 'the recipient email is blank' do
      before do
        gift_card.update!(recipient_email: '')
        gift_card.line_item.order.update!(email: 'gift_card_tester@example.com')
      end

      it 'uses the email associated with the order' do
        expect(subject.to).to contain_exactly('gift_card_tester@example.com')
      end
    end

    context 'when the buyer prints the card' do
      before do
        gift_card.update!(delivery: 'purchaser', recipient_email: 'friend@example.com')
        gift_card.line_item.order.update!(email: 'buyer@example.com')
      end

      it 'sends it to the buyer' do
        expect(subject.to).to contain_exactly('buyer@example.com')
      end
    end

    it 'attaches the card image when enabled' do
      stub_spree_preferences(SolidusVirtualGiftCard::Config, card_image: true)

      attachment = subject.attachments.sole
      expect(attachment).to be_inline
      expect(attachment.mime_type).to eq('image/png')
      expect(attachment.filename).to eq("gift-card-#{gift_card.formatted_redemption_code}.png")
    end

    it 'attaches nothing by default' do
      expect(subject.attachments).to be_empty
    end
  end
end
