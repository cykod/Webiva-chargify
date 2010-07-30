
class ChargifySubscription < DomainModel
  attr_accessor :billing_first_name, :billing_last_name, :expiration_month, :expiration_year, :cvv, :billing_address, :billing_city, :billing_state, :billing_zip, :billing_country, :coupon_code

  belongs_to :chargify_plan
  has_end_user :end_user_id
  has_many :chargify_transactions, :order => 'transaction_id DESC'

  validates_presence_of :end_user_id
  validates_presence_of :chargify_plan_id

  serialize :data
  serialize :components # Hash, component_name => quantity

  has_options :status, [['Invalid', 'invalid'], ['Valid', 'valid'], ['Canceled', 'canceled']]

  named_scope :active_subscription, :conditions => ['subscription_id IS NOT NULL && status = "valid"']

  def name
    "#{self.billing_first_name} #{self.billing_last_name}"
  end

  def credit_card
    @full_number ? @full_number.call : nil
  end

  def credit_card=(v)
    @full_number = v.blank? ? nil : Proc.new { v }
    @full_number ? @full_number.call : nil
  end

  def components
    self.read_attribute(:components) || {}
  end

  def components=(c)
    c = c.to_hash.stringify_keys if c
    self.write_attribute(:components, c)
  end

  def product_handle
    self.chargify_plan.product_handle if self.chargify_plan
  end

  def product_handle=(handle)
    return handle if self.chargify_plan && self.chargify_plan.product_handle == handle

    plan = ChargifyPlan.find_by_product_handle(handle)
    return handle unless plan

    @old_plan ||= self.chargify_plan # ||=, just incase it is called twice, need to keep track of the current plan
    self.chargify_plan_id = plan.id
    self.chargify_plan = plan
    @chargify_components = nil
    handle
  end

  def chargify_components
    @chargify_components ||= self.chargify_plan.chargify_components.collect { |c| c.quantity = self.component_quantity(c.component_id); c }
  end

  def validate
    self.errors.add(:chargify_plan_id, 'is invalid') if self.chargify_plan && self.chargify_plan.available? && self.chargify_plan.handler_info.nil?
    self.errors.add(:subscription_id, 'is missing') if self.status && self.subscription_id.blank?
    self.errors.add(:product_handle, 'is missing') unless self.product_handle

    # Creating a subscription
    if self.subscription_id.nil?
      if ! self.coupon_code.blank? && self.chargify_plan
        chargify_coupon = self.chargify_client.fetch_coupon(self.chargify_plan.product_family_id, self.coupon_code)
        self.errors.add(:coupon_code, 'is invalid') unless chargify_coupon
        self.errors.add(:coupon_code, 'has expired') if chargify_coupon && Time.parse(chargify_coupon['end_date']) < Time.now
      end

      self.errors.add(:credit_card, 'is missing') unless @full_number
    elsif @old_plan  # Editing an existing subscription
      errors = self.plan_handler_obj.can_edit?(self.chargify_plan.product_handle, self.handler_components)
      if ! errors
        self.errors.add(:chargify_plan_id, 'is invalid')
        self.errors.add(:product_handle, 'is invalid')
      elsif errors.is_a?(Array)
        errors.each do |msg|
          msg.is_a?(Array) ? self.errors.add(msg[0], msg[1]) : self.errors.add_to_base(msg)
        end
      end

      invalid_component = self.chargify_components.find { |c| ! c.valid? }
      self.errors.add_to_base("%s is invalid" / invalid_component.display_name) if invalid_component
    end

    # When we are updating billing information, make sure all the data has been provided
    if @full_number
      self.errors.add(:billing_first_name, 'is missing') if self.billing_first_name.blank?
      self.errors.add(:billing_last_name, 'is missing') if self.billing_last_name.blank?
      self.errors.add(:billing_address, 'is missing') if self.billing_address.blank?
      self.errors.add(:billing_city, 'is missing') if self.billing_city.blank?
      self.errors.add(:billing_state, 'is missing') if self.billing_state.blank?
      self.errors.add(:billing_zip, 'is missing') if self.billing_zip.blank?
      self.errors.add(:billing_country, 'is missing') if self.billing_country.blank?

      self.errors.add(:expiration_year, 'is invalid') if self.expiration_year < Time.now.year
      self.errors.add(:expiration_month, 'is invalid') if self.expiration_month > 12

      if self.expiration_year == Time.now.year && self.expiration_month < Time.now.month
        self.errors.add(:expiration_month, 'is invalid') 
        self.errors.add(:expiration_year, 'is invalid') 
      end
    end
  end

  def subscribe
    return false unless self.valid?

    unless self.push_customer
      self.errors.add_to_base "Failed to create chargify customer".t
      return false
    end

    subscription = nil
    begin
      subscription = self.chargify_client.subscribe self.chargify_plan.product_handle, self.end_user_id, self.credit_card_attributes, self.chargify_component_quantities, self.coupon_code
    rescue ActiveWebService::InvalidResponse
      self.errors.add_to_base 'Please check your billing information'.t
      self.status = 'invalid'
      return false
    end

    self.subscription_id = subscription['id']
    self.attributes = subscription.slice('state', 'created_at', 'updated_at', 'expires_at', 'activated_at')
    self.data = subscription
    self.product_family_id = self.chargify_plan.product_family_id
    self.status = 'valid'
    self.save
    self.push_transactions
    self.plan_handler_obj.subscribe(self.data['product']['handle'], self.handler_components)
    true
  end

  def cancel
    return false unless self.valid?

    if self.status == 'canceled'
      self.errors.add_to_base 'Subscription already canceled'.t
      return false
    end

    subscription = nil
    begin
      subscription = self.chargify_client.cancel self.subscription_id
    rescue ActiveWebService::InvalidResponse
      self.errors.add_to_base 'Canceling subscription failed'.t
      return false
    end

    self.attributes = subscription.slice('state', 'created_at', 'updated_at', 'expires_at', 'activated_at')
    self.data = subscription
    self.status = 'canceled'
    self.save
    self.push_transactions
    self.plan_handler_obj.cancel
    true
  end

  def edit
    return false unless self.valid?

    if self.status == 'canceled'
      self.errors.add_to_base 'Subscription is canceled'.t
    end

    begin
      self.chargify_client.edit_credit_card(self.subscription_id, self.credit_card_attributes) if @full_number
    rescue ActiveWebService::InvalidResponse
      self.errors.add_to_base 'Please check your billing information'.t
      self.status = 'invalid'
      return false
    end

    subscription = nil
    begin
      # should break this into edit_credit_card, edit_components, migrate_plan
      old_product_handle = @old_plan ? @old_plan.product_handle : nil
      subscription = self.chargify_client.migrate self.subscription_id, self.product_handle, old_product_handle, self.chargify_component_quantities
    rescue ActiveWebService::InvalidResponse
      self.errors.add(:product_handle, 'is invalid')
      self.errors.add(:components, 'are invalid')
      self.status = 'invalid'
      return false
    end

    @old_plan = nil
    self.subscription_id = subscription['id']
    self.attributes = subscription.slice('state', 'created_at', 'updated_at', 'expires_at', 'activated_at')
    self.data = subscription
    self.product_family_id = self.chargify_plan.product_family_id
    self.status = 'valid'
    self.save
    self.push_transactions
    self.plan_handler_obj.edit(self.data['product']['handle'], self.handler_components)
    true
  end

  def plan_handler_obj
    self.chargify_plan.handler_obj(self.end_user)
  end

  def update_subscription_data
    data = nil
    begin
      data = self.chargify_client.service.subscription self.subscription_id
    rescue ActiveWebService::InvalidResponse
      Rails.logger.error "Failed to update subscription #{self.subscription_id}"
      return
    end

    self.attributes = data.slice('state', 'created_at', 'updated_at', 'expires_at', 'activated_at')
    self.update_attributes :data => data

    self.push_transactions
  end

  def push_transactions
    begin
      self.chargify_client.service.subscription_transactions(self.subscription_id).each do |transaction|
        self.push_transaction transaction
      end
    rescue ActiveWebService::InvalidResponse
    end
  end

  def push_transaction(data)
    transaction = self.chargify_transactions.find_by_transaction_id(data['id']) || self.chargify_transactions.new(:transaction_id => data['id'])
    transaction.update_attributes :data => data, :amount => (data['amount_in_cents'].to_f / 100.0), :charge_type => data['type'], :success => data['success'], :created_at => data['created_at']
    transaction
  end

  def chargify_client
    @chargify_client ||= Chargify::AdminController.module_options.client
  end

  def push_customer
    customer = self.fetch_customer
    return customer if customer

    if self.end_user.first_name.blank? || self.end_user.last_name.blank?
      self.end_user.first_name = self.billing_first_name
      self.end_user.last_name = self.billing_last_name
      self.end_user.save
    end

    begin
      customer = self.chargify_client.service.create_customer :first_name => self.end_user.first_name, :last_name => self.end_user.last_name, :email => self.end_user.email, :reference => self.end_user_id
    rescue ActiveWebService::InvalidResponse
      nil
    end
  end

  def fetch_customer
    begin
      self.chargify_client.service.find_customer_by_reference self.end_user_id
    rescue ActiveWebService::InvalidResponse
      false
    end
  end

  def component_quantity(component_id)
    component = self.chargify_plan.chargify_components.to_a.find { |c| c.component_id == component_id }
    (component ? self.components[component.component_name] : nil) || 0
  end

  def chargify_component_quantities
    ChargifyComponent.valid_component.find(:all, :conditions => {:product_family_id => self.product_family_id}).collect do |component|
      {:component_id => component.component_id, :allocated_quantity => self.component_quantity(component.component_id)}
    end
  end

  def handler_components
    self.chargify_components.collect { |c| {c.component_name(:base => true) => c.quantity} }
  end

  def self.valid_params
    [:product_handle, :components, :billing_first_name, :billing_last_name, :expiration_month, :expiration_year, :cvv, :billing_address, :billing_city, :billing_state, :billing_zip, :billing_country, :coupon_code, :credit_card]
  end

  def billing_first_name
    return @billing_first_name if @billing_first_name

    @billing_first_name = self.get_credit_card_data('first_name')
    @billing_first_name ||= self.end_user.first_name if self.end_user
    @billing_first_name
  end

  def billing_last_name
    return @billing_last_name if @billing_last_name

    @billing_last_name = self.get_credit_card_data('last_name')
    @billing_last_name ||= self.end_user.last_name if self.end_user
    @billing_last_name
  end

  def expiration_year=(year)
    @expiration_year = year.to_i
  end

  def expiration_year
    @expiration_year ||= (self.get_credit_card_data('expiration_year') || Time.now.year).to_i
  end

  def expiration_month
    @expiration_month ||= (self.get_credit_card_data('expiration_month') || 1).to_i
  end

  def expiration_month=(month)
    @expiration_month = month.to_i
  end

  def billing_address
    @billing_address ||= self.get_credit_card_data('billing_address')
  end

  def billing_city
    @billing_city ||= self.get_credit_card_data('billing_city')
  end

  def billing_state
    @billing_state ||= self.get_credit_card_data('billing_state')
  end

  def billing_zip
    @billing_zip ||= self.get_credit_card_data('billing_zip')
  end

  def billing_country
    @billing_country ||= self.get_credit_card_data('billing_country') || 'US'
  end

  def masked_card_number
    self.get_credit_card_data('masked_card_number')
  end

  def card_type
    self.get_credit_card_data('card_type')
  end

  def self.update_subscriptions(opts={})
    subscription_ids = opts[:subscription_ids]
    return unless subscription_ids

    subscription_ids.each do |subscription_id|
      subscription = ChargifySubscription.find_by_subscription_id(subscription_id)
      next unless subscription
      subscription.update_subscription_data
    end
  end

  protected

  def get_credit_card_data(field) #:nodoc:
    self.data && self.data['credit_card'] ? self.data['credit_card'][field] : nil
  end

  def credit_card_attributes
    {
      :first_name => self.billing_first_name,
      :last_name => self.billing_last_name,
      :full_number => @full_number ? @full_number.call : nil,
      :expiration_month => self.expiration_month,
      :expiration_year => self.expiration_year,
      :cvv => self.cvv,
      :billing_address => self.billing_address,
      :billing_city => self.billing_city,
      :billing_state => self.billing_state,
      :billing_zip => self.billing_zip,
      :billing_country => self.billing_country
    }.delete_if { |k,v| v.blank? }
  end
end
