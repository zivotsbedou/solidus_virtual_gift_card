# frozen_string_literal: true

require 'spec_helper'

describe Spree::GiftCardDesign do
  it 'gives each colour role as RGB' do
    design = described_class.new(name: 'Lilac', amount_color: '#ae9ac6')

    expect(design.rgb(:amount)).to eq([174, 154, 198])
  end

  it 'rejects colours that are not #rrggbb' do
    expect(described_class.new(name: 'Bad', ink_color: 'red')).not_to be_valid
  end

  it 'accepts only PNG or JPEG backgrounds' do
    design = described_class.new(name: 'Text')
    design.background.attach(io: StringIO.new('text'), filename: 'card.txt', content_type: 'text/plain')

    expect(design).not_to be_valid
  end

  it 'keeps designs that cards were issued with' do
    design = described_class.create!(name: 'Used')
    create(:virtual_gift_card, design: design)

    expect(design.destroy).to be(false)
  end

  it 'refuses inactive designs for new cards' do
    design = described_class.create!(name: 'Christmas', active: false)

    expect(build(:virtual_gift_card, design: design)).not_to be_valid
  end

  it 'refuses unknown designs for new cards' do
    expect(build(:virtual_gift_card, design_id: 0)).not_to be_valid
  end

  it 'requires a non-negative position' do
    expect(described_class.new(name: 'Blank', position: nil)).not_to be_valid
    expect(described_class.new(name: 'Negative', position: -1)).not_to be_valid
  end

  it 'gives the design ID in details as submitted from a form' do
    design = described_class.create!(name: 'Merch')

    expect(build(:virtual_gift_card, design: design).details[:design_id]).to eq(design.id.to_s)
  end
end
