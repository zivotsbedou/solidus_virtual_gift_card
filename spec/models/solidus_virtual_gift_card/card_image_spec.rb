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

  it 'leaves out empty fields' do
    gift_card.update!(recipient_name: nil, purchaser_name: nil, gift_message: nil)

    expect { described_class.new(gift_card).to_png }.not_to raise_error
  end
end
