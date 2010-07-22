
class Chargify::PostbackController < ApplicationController
  protect_from_forgery :except => :index

  def index
    if request.post?
      key = params[:key]
      if key && key == Chargify::AdminController.module_options.postback_hash
        subscription_ids = JSON.parse(request.body.read)
        ChargifySubscription.run_class_worker(:update_subscriptions, :subscription_ids => subscription_ids) if subscription_ids.is_a?(Array)
      end
    end

    render :nothing => true
  end
end
