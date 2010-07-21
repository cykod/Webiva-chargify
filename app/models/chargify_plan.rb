
class ChargifyPlan < DomainModel
  include HandlerActions

  has_many :chargify_components
  has_many :chargify_subscriptions

  validates_presence_of :name

  serialize :data

  has_options :status, [['Active', 'active'], ['Inactive', 'inactive'], ['Hidden', 'hidden']]

  named_scope :available_plan, :conditions => 'handler IS NOT NULL && status = "active"'

  def validate
    self.errors.add(:handler, 'is invalid') if self.handler && self.handler_info.nil?
  end

  def available?
    self.status == 'active' || self.status == 'hidden'
  end

  def self.push_product(data)
    plan = ChargifyPlan.find_by_product_id(data['id']) || ChargifyPlan.new(:product_id => data['id'])
    plan.update_attributes :name => data['name'], :description => data['description'], :product_family_id => data['product_family']['id'], :product_handle => data['handle'], :data => data
    plan
  end

  def handler=(h)
    self.write_attribute(:handler, h.blank? ? nil : h)
  end

  def handler_obj(end_user)
    @handler_obj ||= self.handler_class.new(end_user) if self.handler_class
  end

  def handler_class
    self.handler_info[:class] if self.handler_info
  end

  def handler_info
    @handler_info ||= self.get_handler_info(:chargify, :plan, self.handler) if self.handler
  end

  def self.handler_options
    self.get_handler_options(:chargify, :plan)
  end
end
