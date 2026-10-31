class CreateGiftCardTemplates < ActiveRecord::Migration[7.0]
  # Card designs become templates (artwork and field layout) that gift card variants pick.
  def change
    create_table :spree_gift_card_templates do |t|
      t.string :name, null: false
      t.json :layout
      t.timestamps
    end
    add_reference :spree_variants, :gift_card_template, foreign_key: { to_table: :spree_gift_card_templates }
    # The template a card was bought with, so later changes to the variant do not redraw it.
    add_reference :spree_virtual_gift_cards, :gift_card_template, foreign_key: { to_table: :spree_gift_card_templates }
    # Keep existing designs and their artwork as templates; their old texts and colours are now
    # part of the artwork and the template layout.
    reversible do |direction|
      direction.up do
        execute <<~SQL
          INSERT INTO spree_gift_card_templates (id, name, created_at, updated_at)
          SELECT id, name, created_at, updated_at FROM spree_gift_card_designs
        SQL
        execute "UPDATE active_storage_attachments SET record_type = 'Spree::GiftCardTemplate' WHERE record_type = 'Spree::GiftCardDesign'"
        connection.reset_pk_sequence!(:spree_gift_card_templates) if connection.respond_to?(:reset_pk_sequence!)
      end
    end
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
