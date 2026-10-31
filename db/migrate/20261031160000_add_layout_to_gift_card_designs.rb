class AddLayoutToGiftCardDesigns < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_gift_card_designs, :layout, :json
    # Designs carry their fixed texts in the artwork; each field's layout carries its font and colour.
    remove_column :spree_gift_card_designs, :heading, :string
    remove_column :spree_gift_card_designs, :footer, :text
    remove_column :spree_gift_card_designs, :footer_align, :string, null: false, default: "centre"
    remove_column :spree_gift_card_designs, :amount_color, :string, null: false, default: "#2d3142"
    remove_column :spree_gift_card_designs, :ink_color, :string, null: false, default: "#2d3142"
    remove_column :spree_gift_card_designs, :box_color, :string, null: false, default: "#2d3142"
  end
end
