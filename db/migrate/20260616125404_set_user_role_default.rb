class SetUserRoleDefault < ActiveRecord::Migration[8.1]
  def up
    change_column_default :users, :role, from: nil, to: "client"
    User.where(role: nil).update_all(role: "client")
  end

  def down
    change_column_default :users, :role, from: "client", to: nil
  end
end
