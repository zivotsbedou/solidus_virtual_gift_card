# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module GiftCardCartUpdate
      def update_cart(params)
        result = super
        if result
          order.line_items.select(&:gift_card?).each { |item| update_gift_cards(item, item.quantity) }
        end
        result
      end

    end

    module OrderContentsDecorator
      include GiftCardCartUpdate
      def add(variant, quantity = 1, options = {})
        ::Spree::LineItem.transaction do
          line_item = super
          create_gift_cards(line_item, quantity, options['gift_card_details'] || {})
          line_item
        end
      end

      def remove(variant, quantity = 1, options = {})
        line_item = super
        remove_gift_cards(line_item, quantity)
        line_item
      end

      private

      # Open-amount gift cards cost what the customer chose; the card validates the range.
      def add_to_line_item(variant, quantity, options = {})
        line_item = super
        if line_item.gift_card_open_amount?
          amount = (options['gift_card_details'] || {})['amount'].to_s.tr(',', '.')
          line_item.update!(price: BigDecimal(amount, exception: false) || 0)
        end
        line_item
      end

      def create_gift_cards(line_item, quantity_diff, gift_card_details = {})
        if line_item.gift_card?
          quantity_diff.to_i.times do
            ::Spree::VirtualGiftCard.create!(
              amount: line_item.price,
              currency: line_item.currency,
              line_item: line_item,
              recipient_name: gift_card_details['recipient_name'],
              recipient_email: gift_card_details['recipient_email'],
              purchaser_name: gift_card_details['purchaser_name'],
              gift_message: gift_card_details['gift_message'],
              delivery: gift_card_details['delivery'].presence || 'recipient',
              gift_card_template: line_item.variant.gift_card_template,
              send_email_at: format_date(gift_card_details['send_email_at'])
            )
          end
        end
      end

      def remove_gift_cards(line_item, quantity_diff)
        if line_item.gift_card?
          line_item.gift_cards.order(:created_at).last(quantity_diff).each(&:destroy!)
        end
      end

      def update_gift_cards(line_item, new_quantity)
        if line_item&.gift_card?
          gift_card_count = line_item.gift_cards.count
          if new_quantity > gift_card_count
            create_gift_cards(line_item, new_quantity - gift_card_count, line_item.gift_cards.first&.details&.stringify_keys || {})
          elsif new_quantity < line_item.gift_cards.count
            remove_gift_cards(line_item, gift_card_count - new_quantity)
          end
        end
      end

      def format_date(date)
        return date if date.acts_like?(:date) || date.acts_like?(:time)
        return Date.current if date.nil?

        begin
          Date.parse(date)
        rescue ArgumentError
          raise ::Spree::GiftCards::GiftCardDateFormatError
        end
      end

      ::Spree::SimpleOrderContents.prepend self
      ::Spree::OrderContents.prepend GiftCardCartUpdate if Object.const_defined?('::Spree::OrderContents')
    end
  end
end
