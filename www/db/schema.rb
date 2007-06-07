# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 2) do

  create_table "customers", :force => true do |t|
    t.column "first_name", :string
    t.column "last_name",  :string
    t.column "email",      :string
  end

  create_table "licenses", :force => true do |t|
    t.column "customer_id", :integer,  :null => false
    t.column "product_id",  :integer,  :null => false
    t.column "created_at",  :datetime
  end

  create_table "products", :force => true do |t|
    t.column "name",  :string
    t.column "uuid",  :string
    t.column "price", :decimal, :precision => 8, :scale => 2, :default => 0.0
  end

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string
    t.column "data",       :text
    t.column "updated_at", :datetime
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

end
