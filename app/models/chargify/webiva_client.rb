
class Chargify::WebivaClient

  def initialize(api_key, subdomain)
    @service = Chargify::WebService.new api_key, subdomain
  end

  def valid?
    begin
      self.service.products
      true
    rescue RESTHome::InvalidResponse
      false
    end
  end

  def service
    @service
  end

  # components = [{:component_id => <id>, :allocated_quantity => 0}, ...]
  def subscribe(product_handle, customer_reference, credit_card_attributes, components=[], coupon_code=nil)
    subscription = {
      :product_handle => product_handle,
      :customer_reference => customer_reference,
      :credit_card_attributes => credit_card_attributes
    }
    subscription[:components] = components unless components.empty?
    subscription[:coupon_code] = coupon_code if coupon_code

    self.service.create_subscription subscription
  end

  def edit_credit_card(subscription_id, credit_card_attributes)
    subscription = {
      :credit_card_attributes => credit_card_attributes
    }
    self.service.edit_subscription subscription_id, subscription
  end

  def migrate(subscription_id, product_handle, old_product_handle, components=[])
    if old_product_handle && product_handle != old_product_handle
      self.service.create_subscription_migration subscription_id, {:product_handle => product_handle}
    end

    components.each do |component|
      self.service.edit_subscription_component subscription_id, component[:component_id], {:allocated_quantity => component[:allocated_quantity]}
    end

    self.service.subscription subscription_id
  end

  def cancel(subscription_id)
    self.service.cancel_subscription subscription_id
  end

  def refresh_db(opts={})
    self.service.products.each do |product|
      ChargifyPlan.push_product product
    end

    if self.service.product_families 
      self.service.product_families.each do |family|
        self.service.components(family['id']).each do |component|
          ChargifyComponent.push_component family['id'], component
        end
      end
    end

    ChargifySubscription.active_subscription.find_in_batches do |subscriptions|
      subscriptions.each do |subscription|
        subscription.update_subscription_data
      end
    end

    true
  end

  def fetch_coupon(product_family_id, coupon_code)
    begin
      self.service.find_coupon_by_code(product_family_id, coupon_code)
    rescue RESTHome::InvalidResponse
      false
    end
  end
end
