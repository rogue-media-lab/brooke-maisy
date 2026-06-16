class ChangeMessagesReadDefault < ActiveRecord::Migration[8.1]
  def change
    Message.where(read: nil).update_all(read: false)
    change_column_default :messages, :read, from: nil, to: false
  end
end
