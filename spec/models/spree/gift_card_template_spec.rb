# frozen_string_literal: true

require 'spec_helper'

describe Spree::GiftCardTemplate do
  let(:base) { { code: { x: 0.3, y: 0.5, width: 0.5, size: 0.05, align: :centre } } }

  it 'accepts only PNG or JPEG artwork' do
    template = described_class.new(name: 'Text')
    template.background.attach(io: StringIO.new('text'), filename: 'card.txt', content_type: 'text/plain')

    expect(template).not_to be_valid
  end

  it 'keeps templates that variants use' do
    template = described_class.create!(name: 'Used')
    create(:variant, gift_card_template: template)

    expect(template.destroy).to be(false)
  end

  it 'keeps templates that cards were bought with' do
    template = described_class.create!(name: 'Bought')
    create(:virtual_gift_card, gift_card_template: template)

    expect(template.destroy).to be(false)
  end

  it 'places fields where staff put them' do
    template = described_class.new(name: 'Moved', layout: '{"code":{"x":0.6,"y":0.2,"size":0.08,"font":"sans bold","color":"#ae9ac6"}}')

    expect(template).to be_valid
    expect(template.card_layout(base)[:code]).to eq(x: 0.6, y: 0.2, width: 0.5, size: 0.08, align: :centre, font: 'sans bold', color: '#ae9ac6')
  end

  it 'takes a layout with symbol keys' do
    template = described_class.new(name: 'Seeded', layout: { code: { color: '#ffffff' } })

    expect(template).to be_valid
    expect(template.card_layout(base)[:code]).to include(color: '#ffffff')
  end

  it 'goes back to the configured layout when cleared' do
    template = described_class.new(name: 'Reset', layout: '')

    expect(template.layout).to be_nil
    expect(template.card_layout(base)).to eq(base)
  end

  it 'rejects layouts that are not fractions of the card, known fonts and colours' do
    ['{"code":{"x":2}}', '{"code":{"colour":"red"}}', 'not json', '{"code":{"color":"red"}}', '{"code":{"font":"Comic Sans"}}'].each do |layout|
      expect(described_class.new(name: 'Bad', layout: layout)).not_to be_valid, layout
    end
  end
end
