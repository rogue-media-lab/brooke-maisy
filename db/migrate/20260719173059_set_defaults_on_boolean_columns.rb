class SetDefaultsOnBooleanColumns < ActiveRecord::Migration[8.1]
  def up
    # Fix is_template on quotes — was NULL, should default to false
    Quote.where(is_template: nil).update_all(is_template: false)
    change_column_default :quotes, :is_template, false
    change_column_null :quotes, :is_template, false

    # Check and fix other common boolean columns that may have NULL issues
    # Product.is_active
    Product.where(is_active: nil).update_all(is_active: true) if column_exists?(:products, :is_active)
    change_column_default :products, :is_active, true if column_exists?(:products, :is_active)
    change_column_null :products, :is_active, false if column_exists?(:products, :is_active)

    # Swatch.is_active
    Swatch.where(is_active: nil).update_all(is_active: true) if column_exists?(:swatches, :is_active)
    change_column_default :swatches, :is_active, true if column_exists?(:swatches, :is_active)
    change_column_null :swatches, :is_active, false if column_exists?(:swatches, :is_active)

    # Message.read
    Message.where(read: nil).update_all(read: false) if column_exists?(:messages, :read)
    change_column_default :messages, :read, false if column_exists?(:messages, :read)
    change_column_null :messages, :read, false if column_exists?(:messages, :read)

    # ProjectUpdate.visible_to_client
    ProjectUpdate.where(visible_to_client: nil).update_all(visible_to_client: true) if column_exists?(:project_updates, :visible_to_client)
    change_column_default :project_updates, :visible_to_client, true if column_exists?(:project_updates, :visible_to_client)
    change_column_null :project_updates, :visible_to_client, false if column_exists?(:project_updates, :visible_to_client)

    # ChecklistItem.active
    ChecklistItem.where(active: nil).update_all(active: true) if column_exists?(:checklist_items, :active)
    change_column_default :checklist_items, :active, true if column_exists?(:checklist_items, :active)
    change_column_null :checklist_items, :active, false if column_exists?(:checklist_items, :active)

    # Service.active
    Service.where(active: nil).update_all(active: true) if column_exists?(:services, :active)
    change_column_default :services, :active, true if column_exists?(:services, :active)
    change_column_null :services, :active, false if column_exists?(:services, :active)

    # TradePartner.active
    TradePartner.where(active: nil).update_all(active: true) if column_exists?(:trade_partners, :active)
    change_column_default :trade_partners, :active, true if column_exists?(:trade_partners, :active)
    change_column_null :trade_partners, :active, false if column_exists?(:trade_partners, :active)
  end

  def down
    change_column_default :quotes, :is_template, nil
    change_column_null :quotes, :is_template, true
  end
end
