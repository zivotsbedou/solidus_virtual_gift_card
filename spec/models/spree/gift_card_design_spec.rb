# frozen_string_literal: true

require 'spec_helper'

describe Spree::GiftCardDesign do
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

  describe '#card_layout' do
    let(:base) { { code: { x: 0.3, y: 0.5, width: 0.5, size: 0.05, align: :centre } } }

    it 'places fields where staff put them' do
      design = described_class.new(name: 'Moved', layout: '{"code":{"x":0.6,"y":0.2,"size":0.08,"font":"sans bold","color":"#ae9ac6"}}')

      expect(design).to be_valid
      expect(design.card_layout(base)[:code]).to eq(x: 0.6, y: 0.2, width: 0.5, size: 0.08, align: :centre, font: 'sans bold', color: '#ae9ac6')
    end

    it 'takes a layout with symbol keys' do
      design = described_class.new(name: 'Seeded', layout: { code: { color: '#ffffff' } })

      expect(design).to be_valid
      expect(design.card_layout(base)[:code]).to include(color: '#ffffff')
    end

    it 'goes back to the configured layout when cleared' do
      expect(described_class.new(layout: '').layout).to be_nil
    end
  end

  it 'rejects layouts that are not fractions of the card' do
    expect(described_class.new(name: 'Bad', layout: '{"code":{"x":2}}')).not_to be_valid
    expect(described_class.new(name: 'Bad', layout: '{"code":{"colour":"red"}}')).not_to be_valid
    expect(described_class.new(name: 'Bad', layout: 'not json')).not_to be_valid
    expect(described_class.new(name: 'Bad', layout: '{"code":{"color":"red"}}')).not_to be_valid
    expect(described_class.new(name: 'Bad', layout: '{"code":{"font":"Comic Sans"}}')).not_to be_valid
  end
end
