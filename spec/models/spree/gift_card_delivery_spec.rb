# frozen_string_literal: true

require 'spec_helper'

describe 'Gift card delivery' do
  let(:order) { create(:order) }
  let(:variant) { create(:variant) }
  let(:contents) { Spree::SimpleOrderContents.new(order) }

  before { variant.product.update!(gift_card: true) }

  def card(details)
    contents.add(variant, 1, 'gift_card_details' => details).gift_cards.last
  end

  it 'keeps the template of the variant bought' do
    template = Spree::GiftCardTemplate.create!(name: 'Christmas')
    variant.update!(gift_card_template: template)

    expect(card({}).gift_card_template).to eq(template)
  end

  it 'sends to the recipient by default' do
    expect(card('recipient_email' => 'friend@example.com').delivery_email).to eq('friend@example.com')
  end

  it 'falls back to the buyer without a recipient email' do
    expect(card({}).delivery_email).to eq(order.email)
  end

  it 'sends to the buyer to print when asked, even with a recipient email' do
    gift_card = card('delivery' => 'purchaser', 'recipient_email' => 'friend@example.com')

    expect(gift_card).to be_purchaser_delivery
    expect(gift_card.delivery_email).to eq(order.email)
  end

  it 'rejects an unknown delivery' do
    expect { card('delivery' => 'pigeon') }.to raise_error(ActiveRecord::RecordInvalid, /Delivery/)
  end
end
