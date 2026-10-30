# frozen_string_literal: true

module SolidusVirtualGiftCard
  class DeliverGiftCardsJob < ActiveJob::Base
    def perform(order)
      order.send_gift_card_emails
      return unless order.can_ship? && order.paid?

      order.shipments.select { |shipment| shipment.ready? && shipment.line_items.all?(&:gift_card?) }.each do |shipment|
        shipment.suppress_mailer = true
        shipment.ship!
      end
    end
  end
end
