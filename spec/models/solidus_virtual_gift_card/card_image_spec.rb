# frozen_string_literal: true

require 'spec_helper'
require 'vips'

describe SolidusVirtualGiftCard::CardImage do
  let(:gift_card) { create(:redeemable_virtual_gift_card, amount: 500, recipient_name: 'Ron', purchaser_name: 'Harry') }

  def decode(png)
    Vips::Image.new_from_buffer(png, '')
  end

  it 'draws the details on a plain card of the configured size' do
    image = decode(described_class.new(gift_card).to_png)

    expect([image.width, image.height]).to eq([1748, 1240])
    expect(image.min).to be < 100 # dark text on the white card
  end

  it 'draws on the gift card product image' do
    background = Vips::Image.black(800, 600).new_from_image([10, 120, 200]).copy(interpretation: :srgb)
    upload = Rack::Test::UploadedFile.new(StringIO.new(background.write_to_buffer('.png')), 'image/png', original_filename: 'card.png')
    gift_card.line_item.variant.images.create!(attachment: upload)

    image = decode(described_class.new(gift_card).to_png)

    expect([image.width, image.height]).to eq([800, 600])
    expect(image.getpoint(5, 5).map(&:round)).to eq([10, 120, 200])
  end

  context 'with a template' do
    let(:layout) do
      { amount: { x: 0.1, y: 0.1, width: 0.8, size: 0.2, color: '#ffffff' },
        code: { x: 0.1, y: 0.4, width: 0.8, height: 0.12, size: 0.1, color: [255, 255, 255], align: :centre },
        qr: { x: 0.7, y: 0.6, size: 0.3 } }
    end

    before do
      background = Vips::Image.black(600, 400).new_from_image([45, 49, 66]).copy(interpretation: :srgb)
      template = Spree::GiftCardTemplate.create!(name: 'Dark')
      template.background.attach(io: StringIO.new(background.write_to_buffer('.png')), filename: 'dark.png', content_type: 'image/png')
      gift_card.line_item.variant.update!(gift_card_template: template)
      allow(SolidusVirtualGiftCard::Config).to receive(:card_image_layout).and_return(layout)
    end

    it 'draws the fields in their colours on the template artwork' do
      image = decode(described_class.new(gift_card).to_png)

      expect([image.width, image.height]).to eq([600, 400])
      expect(image.getpoint(2, 2).map(&:round)).to eq([45, 49, 66])
      expect(image.extract_area(0, 0, 600, 360).max).to eq(255) # white text on the dark card
    end

    it 'draws the QR code only with a URL' do
      plain = decode(described_class.new(gift_card).to_png).extract_area(420, 240, 120, 120)
      allow(SolidusVirtualGiftCard::Config).to receive(:card_qr_url).and_return(->(card) { "https://shop.test/poukaz/#{card.redemption_code}" })
      with_qr = decode(described_class.new(gift_card).to_png).extract_area(420, 240, 120, 120)

      expect((plain - [45, 49, 66]).abs.max).to eq(0)
      expect(with_qr.max).to eq(255)
      expect((with_qr - [45, 49, 66]).abs.min).to eq(0)
    end
  end

  it 'leaves out empty fields' do
    gift_card.update!(recipient_name: nil, purchaser_name: nil, gift_message: nil)

    expect { described_class.new(gift_card).to_png }.not_to raise_error
  end

  it 'places fields where the template layout puts them' do
    template = Spree::GiftCardTemplate.create!(name: 'Moved', layout: { amount: { x: 0.5, y: 0.5, color: '#ff0000' } })
    gift_card.line_item.variant.update!(gift_card_template: template)
    allow(SolidusVirtualGiftCard::Config).to receive(:card_image_layout).and_return(amount: { x: 0.05, y: 0.05, width: 0.4, size: 0.1 })

    image = decode(described_class.new(gift_card).to_png)

    expect(image.extract_area(0, 0, 800, 560).min).to eq(255) # nothing left in the default spot
    expect(image.extract_area(874, 620, 700, 200).min).to be < 100
  end
end
