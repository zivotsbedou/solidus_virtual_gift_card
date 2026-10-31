class CreateGiftCardTemplates < ActiveRecord::Migration[7.0]
  # Card designs become templates (artwork and field layout) that gift card variants pick.
  def change
    create_table :spree_gift_card_templates do |t|
      t.string :name, null: false
      t.json :layout
      t.timestamps
    end
    add_reference :spree_variants, :gift_card_template, foreign_key: { to_table: :spree_gift_card_templates }
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
