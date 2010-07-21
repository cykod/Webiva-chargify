
class Chargify::TestHandler < Chargify::PlanHandler

  def self.chargify_plan_handler_info
    {
      :name => 'Test Handler'
    }
  end

  def subscribe(product_identifier,components = {})
  end

  def cancel
  end

  def edit(product_identifier,components = {})
  end

  def can_edit?(product_identifier,components = {})
    true
  end
end
