
class Chargify::ManageController < ModuleController
  permit 'chargify_manage'

  component_info 'Chargify'

  # need to include 
  include ActiveTable::Controller
  active_table :chargify_plans_table,
                ChargifyPlan,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, :name),
                  hdr(:string, :status),
                  hdr(:string, :description)
                ]

  active_table :chargify_subscriptions_table,
                ChargifySubscription,
                [ hdr(:icon, '', :width=>10),
                  hdr(:static, '', :width=>65),
                  hdr(:static, 'Plan'),
                  hdr(:static, 'User'),
                  :created_at
                ]

  active_table :chargify_components_table,
                ChargifyComponent,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, :name),
                  hdr(:static, 'Plan')
                ]

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }


  def plans
    cms_page_path ['Content'], "Chargify Plans"
    display_chargify_plans_table(false)
  end

  def display_chargify_plans_table(display=true)
    active_table_action 'chargify_plan' do |act,ids|
      case act
      when 'active'
        ChargifyPlan.update_all "status = 'active'", {:id => ids}
      when 'inactive'
        ChargifyPlan.update_all "status = 'inactive'", {:id => ids}
      when 'hidden'
        ChargifyPlan.update_all "status = 'hidden'", {:id => ids}
      end
    end

    @active_table_output = chargify_plans_table_generate params, :order => 'name', :conditions => 'handler IS NOT NULL'
    render :partial => 'chargify_plans_table' if display
  end

  def subscriptions
    cms_page_path ['Content'], "Chargify Subscriptions"
    display_chargify_subscriptions_table(false)
  end

  def display_chargify_subscriptions_table(display=true)
    active_table_action 'chargify_subscription' do |act,ids|
    end

    @active_table_output = chargify_subscriptions_table_generate params, :order => 'created_at DESC'
    render :partial => 'chargify_subscriptions_table' if display
  end

  def transactions
    @subscription = ChargifySubscription.find params[:path][0]
    render :partial => 'transactions'
  end
end
