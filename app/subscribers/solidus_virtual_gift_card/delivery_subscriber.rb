# frozen_string_literal: true

module SolidusVirtualGiftCard
  class DeliverySubscriber
    include Omnes::Subscriber

    handle :order_finalized, with: :deliver, id: :gift_cards_finalized
    handle :order_recalculated, with: :deliver, id: :gift_cards_recalculated

    def deliver(event)
      order = event[:order]
      return unless order.completed? && order.paid? && !order.canceled? && order.gift_cards.exists?

      ActiveRecord.after_all_transactions_commit { DeliverGiftCardsJob.perform_later(order) }
    end
  end
end
