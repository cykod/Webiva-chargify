
class ChargifyComponent < DomainModel

  attr_accessor :quantity

  belongs_to :chargify_plan

  validates_presence_of :name

  serialize :data

  named_scope :valid_component, :conditions => 'chargify_plan_id IS NOT NULL'

  def component_name(opts={})
    return self.name.sub(self.chargify_plan.name, '').downcase.strip.gsub(' ', '_') if opts[:base]
    return @component_name if @component_name
    @component_name = self.name.downcase.strip.gsub(' ', '_')
  end

  def display_name
    return self.name unless self.chargify_plan
    self.name.sub(self.chargify_plan.name, '').strip
  end

  def self.push_component(product_family_id, data)
    component = ChargifyComponent.find_by_component_id(data['id']) || ChargifyComponent.new(:component_id => data['id'])
    component.update_attributes :name => data['name'], :data => data, :product_family_id => product_family_id
    component
  end
end
