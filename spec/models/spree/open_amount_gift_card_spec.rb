# frozen_string_literal: true

require 'spec_helper'

describe 'Open-amount gift cards' do
  let(:order) { create(:order) }
  let(:variant) { create(:variant, price: 10) }
  let(:contents) { Spree::SimpleOrderContents.new(order) }
  let(:options) { { 'gift_card_details' => { 'amount' => '750', 'recipient_name' => 'Ron' } } }

  before do
    variant.product.update!(gift_card: true, gift_card_open_amount: true)
    allow(SolidusVirtualGiftCard::Config).to receive(:open_amount_range).and_return(100..10_000)
  end

  it 'charges and issues the amount the customer chose' do
    line_item = contents.add(variant, 2, options)

    expect(line_item.price).to eq(750)
    expect(line_item.gift_cards.map(&:amount)).to eq([750, 750])
    expect(order.reload.item_total).to eq(1500)
  end

  it 'keeps the chosen amount when Solidus recalculates cart prices' do
    line_item = contents.add(variant, 1, options)
    stub_spree_preferences(recalculate_cart_prices: true)

    order.recalculate

    expect(line_item.reload.price).to eq(750)
  end

  it 'accepts a decimal comma' do
    expect(contents.add(variant, 1, 'gift_card_details' => { 'amount' => '250,50' }).price).to eq(250.5)
  end

  [['50', /greater than or equal to 100/], ['20000', /less than or equal to 10000/], ['abc', /greater than 0/]].each do |amount, message|
    it "rejects #{amount} without adding anything" do
      expect { contents.add(variant, 1, 'gift_card_details' => { 'amount' => amount }) }
        .to raise_error(ActiveRecord::RecordInvalid, message)
      expect(order.line_items.reload).to be_empty
    end
  end

  it 'excludes the end of an exclusive range' do
    allow(SolidusVirtualGiftCard::Config).to receive(:open_amount_range).and_return(100...10_000)

    expect { contents.add(variant, 1, 'gift_card_details' => { 'amount' => '10000' }) }
      .to raise_error(ActiveRecord::RecordInvalid, /less than 10000/)
  end

  it 'ignores a submitted amount for fixed-price gift cards' do
    variant.product.update!(gift_card_open_amount: false)

    expect(contents.add(variant, 1, options).price).to eq(10)
  end
end
