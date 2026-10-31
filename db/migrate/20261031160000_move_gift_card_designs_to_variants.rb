class MoveGiftCardDesignsToVariants < ActiveRecord::Migration[7.0]
  # Card designs are variants of the gift card product: the artwork is the variant image and the
  # card layout is stored on the variant.
  def change
    add_column :spree_variants, :gift_card_layout, :json
    remove_reference :spree_virtual_gift_cards, :design, foreign_key: { to_table: :spree_gift_card_designs }, index: true
    drop_table :spree_gift_card_designs do |t|
      t.string :name, null: false
      t.string :heading
      t.text :footer
      t.string :footer_align, null: false, default: "centre"
      t.string :amount_color, null: false, default: "#2d3142"
      t.string :ink_color, null: false, default: "#2d3142"
      t.string :box_color, null: false, default: "#2d3142"
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
