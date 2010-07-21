
class Chargify::PlanHandler

  def initialize(user)
    @user = user
  end

  def user; @user; end

  # product_identifier is the product_handle in Chargify
  # handler methos are triggered after the subscription has been modified.
  # subscribe(product_identifier,components = {})
  # cancel()
  # edit(product_identifier,components = {})
  # can_edit?(product_identifier,components = {})

end
