# frozen_string_literal: true

require 'spec_helper'

describe Spree::Variant, 'gift card layout' do
  let(:variant) { build(:variant) }
  let(:base) { { code: { x: 0.3, y: 0.5, width: 0.5, size: 0.05, align: :centre } } }

  it 'places fields where staff put them' do
    variant.gift_card_layout = '{"code":{"x":0.6,"y":0.2,"size":0.08,"font":"sans bold","color":"#ae9ac6"}}'

    expect(variant).to be_valid
    expect(variant.card_layout(base)[:code]).to eq(x: 0.6, y: 0.2, width: 0.5, size: 0.08, align: :centre, font: 'sans bold', color: '#ae9ac6')
  end

  it 'takes a layout with symbol keys' do
    variant.gift_card_layout = { code: { color: '#ffffff' } }

    expect(variant).to be_valid
    expect(variant.card_layout(base)[:code]).to include(color: '#ffffff')
  end

  it 'goes back to the configured layout when cleared' do
    variant.gift_card_layout = ''

    expect(variant.gift_card_layout).to be_nil
    expect(variant.card_layout(base)).to eq(base)
  end

  it 'rejects layouts that are not fractions of the card, known fonts and colours' do
    ['{"code":{"x":2}}', '{"code":{"colour":"red"}}', 'not json', '{"code":{"color":"red"}}', '{"code":{"font":"Comic Sans"}}'].each do |layout|
      expect(build(:variant, gift_card_layout: layout)).not_to be_valid, layout
    end
  end
end
