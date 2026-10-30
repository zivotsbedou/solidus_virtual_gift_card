require 'spec_helper'

RSpec.describe Spree::PaymentMethod::GiftCard do
  let(:method) { create(:gift_card_payment_method) }
  let(:card) { create(:redeemable_virtual_gift_card, amount: 500) }

  it 'captures once and limits cumulative refunds to the capture' do
    response = method.purchase(20000, card, currency: card.currency)
    expect(response).to be_success
    expect(card.reload.amount_remaining).to eq(300)
    expect(method.capture(20000, response.authorization, currency: card.currency)).to be_success
    expect(card.reload.amount_remaining).to eq(300)
    expect(method.credit(20000, response.authorization, currency: card.currency)).to be_success
    expect(method.credit(20000, response.authorization, currency: card.currency)).not_to be_success
    expect(card.reload.amount_remaining).to eq(500)
  end

  it 'rejects an inactive card even when its code is known' do
    card.update!(redeemable: false)
    expect(method.purchase(10000, card, currency: card.currency)).not_to be_success
    expect(card.reload.amount_remaining).to eq(500)
  end

  it 'refuses redemption after the original purchase is canceled' do
    card.order.update!(state: 'canceled')
    expect(method.purchase(10000, card, currency: card.currency)).not_to be_success
  end

  it 'voids a reservation only once' do
    response = method.authorize(10000, card, currency: card.currency)
    expect(response).to be_success
    2.times { expect(method.void(response.authorization)).to be_success }
    expect(card.reload.amount_authorized).to eq(0)
  end
  it 'also caps refunds when configured to issue a replacement card' do
    allow(SolidusVirtualGiftCard::Config).to receive(:credit_to_new_gift_card).and_return(true)
    response = method.purchase(20000, card, currency: card.currency)
    expect(method.credit(20000, response.authorization, currency: card.currency)).to be_success
    expect(method.credit(20000, response.authorization, currency: card.currency)).not_to be_success
  end

end
