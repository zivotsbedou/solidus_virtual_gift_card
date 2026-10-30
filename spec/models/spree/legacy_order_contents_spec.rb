require 'spec_helper'

RSpec.describe 'Gift cards with legacy promotions' do
  it 'creates, updates and removes cards through inherited order contents hooks' do
    order = create(:order)
    variant = create(:variant, track_inventory: false)
    variant.product.update!(gift_card: true)
    contents = Spree::OrderContents.new(order)
    item = contents.add(variant, 1)
    expect(item.gift_cards.count).to eq(1)
    expect(contents.update_cart(line_items_attributes: { id: item.id, quantity: 3, options: {} })).to be_truthy
    expect(item.gift_cards.count).to eq(3)
    contents.remove(variant, 1)
    expect(item.gift_cards.count).to eq(2)
  end
end
