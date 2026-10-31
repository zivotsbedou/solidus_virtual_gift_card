class AddLayoutToGiftCardDesigns < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_gift_card_designs, :layout, :json
    # Designs carry their heading and footer in the artwork.
    remove_column :spree_gift_card_designs, :heading, :string
    remove_column :spree_gift_card_designs, :footer, :text
    remove_column :spree_gift_card_designs, :footer_align, :string, null: false, default: "centre"
  end
end
