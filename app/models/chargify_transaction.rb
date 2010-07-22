
class ChargifyTransaction < DomainModel
  belongs_to :chargify_subscription

  serialize :data

  validates_presence_of :chargify_subscription_id

  after_create :create_shop_order

  def memo
    self.data ? self.data['memo'] : nil
  end

  def create_shop_order
    if self.charge_type == 'Payment' && self.success
      adr = {
        :first_name => self.chargify_subscription.billing_first_name,
        :last_name => self.chargify_subscription.billing_last_name,
        :address => self.chargify_subscription.billing_address,
        :city => self.chargify_subscription.billing_city,
        :state => self.chargify_subscription.billing_state,
        :zip => self.chargify_subscription.billing_zip,
        :country => self.chargify_subscription.billing_country
      }

      order = Shop::ShopOrder.create(
        :end_user_id => self.chargify_subscription.end_user_id,
        :name => self.chargify_subscription.end_user.name,
        :ordered_at => self.created_at,
        :currency => 'USD',
        :state => 'success',
        :subtotal => self.amount,
        :total => self.amount,
        :tax => 0.0,
        :shipping => 0.0,
        :shipping_address => adr,
        :billing_address =>  adr)
      order.update_attribute(:state,'paid')

      order.order_items.create(:item_name => self.chargify_subscription.chargify_plan.name,
                               :order_item => self.chargify_subscription.chargify_plan,
                               :currency => 'USD',
                               :unit_price => self.amount,
                               :quantity => 1,
                               :subtotal => self.amount)
      order
    end
  end
end
