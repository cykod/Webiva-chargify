
class Chargify::AdminController < ModuleController

  component_info 'Chargify', :description => 'Chargify support',
    :access => :private, :dependencies => ['shop']

  # Register a handler feature
  register_permission_category :chargify, "Chargify" ,"Permissions related to Chargify"

  register_permissions :chargify, [ [ :manage, 'Manage Chargify', 'Manage Chargify' ],
    [ :config, 'Configure Chargify', 'Configure Chargify' ]
  ]
  cms_admin_paths "options",
    "Chargify Options" => { :action => 'options' },
    "Options" => { :controller => '/options' },
    "Modules" => { :controller => '/modules' }

  permit 'chargify_config'

  content_model :chargify

  register_handler :chargify, :plan, 'Chargify::TestHandler' if Rails.env == 'test'
  register_handler :chargify, :plan, 'Chargify::SubscriptionHandler'

  # need to include 
  include ActiveTable::Controller
  active_table :chargify_components_table,
                ChargifyComponent,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, :name),
                  hdr(:static, 'Plan')
                ]

  register_action '/chargify/plan/subscribe', :description => 'Chargify New Subscription'
  register_action '/chargify/plan/edit', :description => 'Chargify Edit Subscription'
  register_action '/chargify/plan/cancel', :description => 'Chargify Subscription Canceled'
  register_action '/chargify/subscription/subscribe_failure', :description => 'Chargify Subscription Failure'
  register_action '/chargify/subscription/credit_card_failure', :description => 'Chargify Edit Credit Card Failure'
  register_action '/chargify/subscription/migrate_failure', :description => 'Chargify Change Plan Failure'

  public

  def self.get_chargify_info
    [
      {:name => 'Chargify', :url => {:controller => '/chargify/manage', :action => 'plans'}, :permission => 'chargify_manage', :icon => 'icons/content/feedback.gif'}
    ]
  end

  def options
    cms_page_path ['Options','Modules'], "Chargify Options"

    @options = self.class.module_options(params[:options])

    @options.postback_hash = DomainModel.generate_hash[0..7] if @options.postback_hash.blank?

    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Chargify module options".t
      if ChargifyPlan.count > 0
        redirect_to :action => 'setup'
      else
        redirect_to :action => 'refresh'
      end
      return
    end
  end

  def setup
    cms_page_path ['Options','Modules',"Chargify Options"], "Chargify Plan Setup"

    @options = self.class.module_options
    if ! @options.valid?
      flash[:notice] = "Invalid Chargify settings".t
      redirect_to :action => 'options'
      return
    end

    @plans = ChargifyPlan.find :all
    @handler_options = [["--Select Chargify Plan Handler--", nil]] + ChargifyPlan.handler_options

    if request.post?
      if params[:commit]
        @plans.each do |plan|
          plan.update_attribute :handler, params["plans_#{plan.id}"][:handler]
        end
      end

      if ChargifyComponent.count > 0
        redirect_to :action => 'components'
      else
        redirect_to :controller => '/chargify/manage', :action => 'plans'
      end
      return
    end
  end

  def refresh
    @options = self.class.module_options
    if ! @options.valid?
      flash[:notice] = "Invalid Chargify settings".t
      redirect_to :action => 'options'
      return
    end

    self.class.module_options.client.refresh_db
    redirect_to :action => 'setup'
  end

  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  def components
    cms_page_path ['Options','Modules',"Chargify Options"], "Chargify Component Setup"
    display_chargify_components_table(false)
  end

  def display_chargify_components_table(display=true)
    active_table_action 'chargify_component' do |act,ids|
      case act
      when 'plan'
        plan = params[:plan]
        plan = 'NULL' if plan.blank?
        ChargifyComponent.update_all "chargify_plan_id = #{plan}", {:id => ids}
      end
    end

    @active_table_output = chargify_components_table_generate params, :order => 'name'
    render :partial => 'chargify_components_table' if display
  end

  def select_plan
    render :partial => 'select_plan'
  end

  def subscription
    cms_page_path ['Options','Modules',"Chargify Options"], "Chargify Subscription Options"

    @options = Chargify::SubscriptionHandler.handler_options params[:options]

    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Chargify Subscription options".t
      redirect_to :action => 'options'
    end
  end

  class Options < HashModel
    attributes :api_key => nil, :subdomain => nil, :postback_hash => nil
    validates_presence_of :api_key
    validates_presence_of :subdomain
    validates_presence_of :postback_hash

    options_form(
                 fld(:api_key, :text_field),
                 fld(:subdomain, :text_field, :description => 'https://<subdomain>.chargify.com'),
                 fld(:postback_hash, :text_field, :description => 'Auto generated random hash')
                 )

    def validate
      if self.api_key && self.subdomain && ! self.client.valid?
        self.errors.add(:api_key, 'is invalid')
        self.errors.add(:subdomain, 'is invalid')
      end
    end

    def client
      @client ||= Chargify::WebivaClient.new self.api_key, self.subdomain
    end
  end
end
