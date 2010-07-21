class InitialSetup < ActiveRecord::Migration
  def self.up
    create_table :chargify_plans, :force => true do |t|
      t.string :name
      t.text :description
      t.string :status
      t.text :data
      t.string :handler
      t.integer :product_family_id
      t.integer :product_id
      t.string :product_handle
    end

    create_table :chargify_components, :force => true do |t|
      t.string :name
      t.text :data
      t.integer :chargify_plan_id
      t.integer :product_family_id
      t.integer :component_id
    end

    create_table :chargify_subscriptions, :force => true do |t|
      t.integer :chargify_plan_id
      t.integer :end_user_id
      t.integer :product_family_id
      t.text :data
      t.text :components
      t.string :status
      t.string :state
      t.integer :subscription_id
      t.datetime :activated_at
      t.datetime :expires_at
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :chargify_transactions, :force => true do |t|
      t.integer :chargify_subscription_id
      t.text :data
      t.decimal :amount
      t.string :charge_type
      t.boolean :success
      t.datetime :created_at
      t.integer :transaction_id
    end
  end

  def self.down
    drop_table :chargify_plans
    drop_table :chargify_components
    drop_table :chargify_subscriptions
    drop_table :chargify_transactions
  end
end
