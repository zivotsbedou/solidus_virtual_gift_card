class AddLayoutToGiftCardDesigns < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_gift_card_designs, :layout, :json
  end
end
