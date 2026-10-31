class AddOpenAmountAndDeliveryToGiftCards < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_products, :gift_card_open_amount, :boolean, default: false, null: false
    add_column :spree_virtual_gift_cards, :delivery, :string, default: "recipient", null: false
  end
end
