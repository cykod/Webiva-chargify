require  File.expand_path(File.dirname(__FILE__)) + '/../chargify_spec_helper'

describe ChargifySubscription do

  reset_domain_tables :chargify_plan, :chargify_component, :chargify_subscription, :end_user, :chargify_transaction

  before(:each) do
    FakeWeb.allow_net_connect = false
    FakeWeb.clean_registry

    ChargifyPlan.should_receive(:get_handler_info).with(:chargify, :plan, ChargifySpecTestPlanHandler.to_s.underscore, false).any_number_of_times.and_return({:name => 'Test', :class => ChargifySpecTestPlanHandler})

    @basic_plan = ChargifyPlan.push_product "product_family"=>{"name"=>"Plans", "handle"=>"plans", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"Basic Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"basic-plan", "return_url"=>"", "price_in_cents"=>1500, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6666, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get setup now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"
    @basic_plan.update_attributes :handler => ChargifySpecTestPlanHandler.to_s.underscore, :status => 'active'

    @power_plan = ChargifyPlan.push_product "product_family"=>{"name"=>"Plans", "handle"=>"plans", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"Power Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"power-plan", "return_url"=>"", "price_in_cents"=>1500, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6667, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get more power now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"
    @power_plan.update_attributes :handler => ChargifySpecTestPlanHandler.to_s.underscore, :status => 'active'

    @invalid_plan = ChargifyPlan.push_product "product_family"=>{"name"=>"Plans", "handle"=>"plans", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"Invalid Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"basic-plan", "return_url"=>"", "price_in_cents"=>1500, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6668, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get setup now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"

    @components = [{"kind"=>"quantity_based_component", "name"=>"File storage", "created_at"=>"2010-07-08T12:51:06-04:00", "updated_at"=>"2010-07-08T12:51:06-04:00", "id"=>772, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"GB"}, {"kind"=>"quantity_based_component", "name"=>"Domains", "created_at"=>"2010-07-08T12:57:51-04:00", "updated_at"=>"2010-07-08T12:57:51-04:00", "id"=>773, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"domain"}, {"kind"=>"quantity_based_component", "name"=>"Client Users", "created_at"=>"2010-07-08T13:00:57-04:00", "updated_at"=>"2010-07-08T13:00:57-04:00", "id"=>774, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"client user"}]

    @components.each do |data|
      component = ChargifyComponent.push_component 2091, data
      component.update_attributes :chargify_plan_id => @power_plan.id
    end

    @transactions = [{"created_at"=>"2010-07-21T12:36:39-04:00", "product_id"=>6666, "ending_balance_in_cents"=>0, "memo"=>"Bogus Gateway: Forced success", "id"=>839904, "amount_in_cents"=>2000, "type"=>"PaymentAuthorization", "subscription_id"=>82, "success"=>true}, {"created_at"=>"2010-07-21T12:36:38-04:00", "product_id"=>6666, "ending_balance_in_cents"=>2000, "memo"=>"Initial/Startup fees", "id"=>839902, "amount_in_cents"=>500, "type"=>"Charge", "subscription_id"=>82, "success"=>true}, {"created_at"=>"2010-07-21T12:36:38-04:00", "product_id"=>6666, "ending_balance_in_cents"=>1500, "memo"=>"Basic Plan (recurring charge)", "id"=>839901, "amount_in_cents"=>1500, "type"=>"Charge", "subscription_id"=>82, "success"=>true}]

    year = Time.now.year
    @valid_coupon = {"name"=>"$20 off", "start_date"=>"2010-07-20T18:03:32-04:00", "created_at"=>"2010-07-20T18:03:32-04:00", "code"=>"20OFF", "updated_at"=>"2010-07-20T18:03:32-04:00", "id"=>347, "percentage"=>nil, "amount_in_cents"=>2000, "description"=>"Get $20 off", "product_family_id"=>2091, "end_date"=>"#{year+1}-01-01T01:01:00-05:00"}

    @expired_coupon = {"name"=>"$10 off", "start_date"=>"2010-07-20T18:03:32-04:00", "created_at"=>"2010-07-20T18:03:32-04:00", "code"=>"10OFF", "updated_at"=>"2010-07-20T18:03:32-04:00", "id"=>346, "percentage"=>nil, "amount_in_cents"=>1000, "description"=>"Get $10 off", "product_family_id"=>2091, "end_date"=>"#{year-1}-01-01T01:01:00-05:00"}

    @user = EndUser.push_target 'test_user1@test.dev', :first_name => 'Tester', :last_name => 'Last'

    @client = Chargify::WebivaClient.new 'fake', 'test'
    @client.should_receive(:valid?).any_number_of_times.and_return(true)
    @options = Chargify::AdminController.module_options
    @options.should_receive(:client).any_number_of_times.and_return(@client)
    @options.api_key = 'fake'
    @options.subdomain = 'test'
    Configuration.set_config_model(@options)
  end

  it "should require a plan and a user" do
    subscription = ChargifySubscription.new
    subscription.valid?.should be_false
    subscription.should have(1).error_on(:chargify_plan_id)
    subscription.should have(1).error_on(:end_user_id)
    subscription.should have(1).error_on(:product_handle)
    subscription.should have(1).error_on(:credit_card)
  end

  describe "Subscribing" do
    it "should be able to subscribe to a valid plan" do
      # Force subscription to push customer
      fakeweb_chargify_customer_lookup @user.id

      fakeweb_chargify_create_customer :customer => {"address"=>"56 Rolland St", "city"=>"Charlestown", "reference"=>"#{@user.id}", "created_at"=>"2010-07-09T17:15:13-04:00", "zip"=>"02112", "country"=>"US", "updated_at"=>"2010-07-13T11:15:46-04:00", "id"=>87412, "last_name"=>@user.last_name, "address_2"=>"", "phone"=>"555-555-5555", "organization"=>"", "email"=>@user.email, "state"=>"MA", "first_name"=>@user.first_name}

      fakeweb_chargify_create_subscription :subscription => subscription_response(@basic_plan, @user)

      fakeweb_chargify_transactions 82, @transactions

      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '1', :expiration_month => '1', :expiration_year => (Time.now.year+1), :billing_first_name => 'Tester', :billing_last_name => 'Last', :billing_address => '56 Rolland St', :billing_city => 'Charlestown', :billing_state => 'MA', :billing_zip => '02112'
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_true
      subscription.id.should_not be_nil
      subscription.product_family_id.should == @basic_plan.product_family_id
    end

    it "should not allow invalid credit cards" do
      fakeweb_chargify_customer_lookup @user.id, :customer => {"address"=>"", "city"=>"", "reference"=>"#{@user.id}", "created_at"=>"2010-07-09T17:15:13-04:00", "zip"=>"", "country"=>"USA", "updated_at"=>"2010-07-13T11:15:46-04:00", "id"=>87412, "last_name"=>@user.last_name, "address_2"=>"", "phone"=>"555-555-5555", "organization"=>"", "email"=>@user.email, "state"=>"MA", "first_name"=>@user.first_name}

      fakeweb_chargify_create_subscription_failure :errors => ['Bogus Gateway: Forced failure']

      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '2', :expiration_month => '1', :expiration_year => (Time.now.year+1), :billing_first_name => 'Tester', :billing_last_name => 'Last', :billing_address => '56 Rolland St', :billing_city => 'Charlestown', :billing_state => 'MA', :billing_zip => '02112'
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_false
      subscription.id.should be_nil
      subscription.errors.on(:base).should_not be_nil
    end

    it "should check for invalid expiration date" do
      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '2', :expiration_month => '1', :expiration_year => (Time.now.year-1), :billing_first_name => 'Tester', :billing_last_name => 'Last', :billing_address => '56 Rolland St', :billing_city => 'Charlestown', :billing_state => 'MA', :billing_zip => '02112'
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_false
      subscription.id.should be_nil
      subscription.errors.on(:expiration_year).should_not be_nil
    end

    it "should be able to subscribe to a valid plan with a coupon" do
      fakeweb_chargify_get_coupon 2091, '20OFF', :coupon => @valid_coupon

      fakeweb_chargify_customer_lookup @user.id, :customer => {"address"=>"", "city"=>"", "reference"=>"#{@user.id}", "created_at"=>"2010-07-09T17:15:13-04:00", "zip"=>"", "country"=>"USA", "updated_at"=>"2010-07-13T11:15:46-04:00", "id"=>87412, "last_name"=>@user.last_name, "address_2"=>"", "phone"=>"555-555-5555", "organization"=>"", "email"=>@user.email, "state"=>"MA", "first_name"=>@user.first_name}

      fakeweb_chargify_create_subscription :subscription => subscription_response(@basic_plan, @user)

      fakeweb_chargify_transactions 82, @transactions

      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '1', :expiration_month => '1', :expiration_year => (Time.now.year+1), :coupon_code => '20OFF', :billing_first_name => 'Tester', :billing_last_name => 'Last', :billing_address => '56 Rolland St', :billing_city => 'Charlestown', :billing_state => 'MA', :billing_zip => '02112'
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_true
      subscription.id.should_not be_nil
      subscription.product_family_id.should == @basic_plan.product_family_id
    end

    it "should not be able to subscribe to a valid plan with an expired coupon" do
      fakeweb_chargify_get_coupon 2091, '10OFF', :coupon => @expired_coupon

      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '1', :expiration_month => '1', :expiration_year => (Time.now.year+1), :coupon_code => '10OFF', :billing_first_name => 'Tester', :billing_last_name => 'Last', :billing_address => '56 Rolland St', :billing_city => 'Charlestown', :billing_state => 'MA', :billing_zip => '02112'
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_false
    end

    it "should not be able to subscribe to a valid plan with an invalid coupon" do
      fakeweb_chargify_get_coupon 2091, 'INVALID'

      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '1', :expiration_month => '1', :expiration_year => (Time.now.year+1), :coupon_code => 'INVALID', :billing_first_name => 'Tester', :billing_last_name => 'Last', :billing_address => '56 Rolland St', :billing_city => 'Charlestown', :billing_state => 'MA', :billing_zip => '02112'
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_false
    end

    it "should check for missging billing data" do
      subscription = ChargifySubscription.new :product_handle => 'basic-plan', :credit_card => '1', :expiration_month => '1', :expiration_year => (Time.now.year-1)
      subscription.end_user_id = @user.id
      subscription.subscribe.should be_false
      subscription.id.should be_nil
      subscription.errors.on(:billing_address).should_not be_nil
      subscription.errors.on(:billing_city).should_not be_nil
      subscription.errors.on(:billing_state).should_not be_nil
      subscription.errors.on(:billing_zip).should_not be_nil
    end
  end

  describe "Editing" do
    before(:each) do
      data = subscription_response @basic_plan, @user
      @subscription = ChargifySubscription.create :chargify_plan_id => @basic_plan.id, :end_user_id => @user.id, :product_family_id => @basic_plan.product_family_id, :status => 'valid', :components => nil, :data => data, :state => data['state'], :subscription_id => data['id'], :activated_at => data['activated_at'], :expires_at => data['expires_at'], :created_at => data['created_at'], :updated_at => data['updated_at']
    end

    it "should be able to change subscription plans" do
      @components.each do |component|
        fakeweb_chargify_edit_subscription_component 82, component['id'], :component => component
      end

      fakeweb_chargify_create_subscription_migration 82, :subscription => subscription_response(@power_plan, @user)
      fakeweb_chargify_edit_subscription 82, :subscription => subscription_response(@power_plan, @user)
      fakeweb_chargify_get_subscription 82, :subscription => subscription_response(@power_plan, @user)
      fakeweb_chargify_transactions 82, @transactions

      @subscription.attributes = {:product_handle => @power_plan.product_handle, :components => {:file_storage => 10}, :credit_card => '1', :expiration_month => '1', :expiration_year => (Time.now.year+1)}
      @subscription.edit.should be_true
      @subscription.component_quantity(772).should == 10
    end

    it "should not be able to change subscription plans with a bad credit card" do
      fakeweb_chargify_edit_subscription_failure 82, :errors => ['Bogus Gateway: Forced failure']

      @subscription.attributes = {:product_handle => @power_plan.product_handle, :components => {:file_storage => 10}, :credit_card => '2', :expiration_month => '1', :expiration_year => (Time.now.year+1)}
      @subscription.edit.should be_false
      @subscription.errors.on(:base).should_not be_nil
    end
  end

  describe "Canceling" do
    before(:each) do
      data = subscription_response @basic_plan, @user
      @subscription = ChargifySubscription.create :chargify_plan_id => @basic_plan.id, :end_user_id => @user.id, :product_family_id => @basic_plan.product_family_id, :status => 'valid', :components => nil, :data => data, :state => data['state'], :subscription_id => data['id'], :activated_at => data['activated_at'], :expires_at => data['expires_at'], :created_at => data['created_at'], :updated_at => data['updated_at']
    end

    it "should be able to cancel a subscription" do
      fakeweb_chargify_cancel_subscription 82, :subscription => subscription_response(@basic_plan, @user)
      fakeweb_chargify_transactions 82, @transactions
      @subscription.cancel.should be_true
      @subscription.status.should == 'canceled'
    end

    it "should not be able to cancel a subscription that is already canceled" do
      @subscription.update_attributes :status => 'canceled'
      @subscription.cancel.should be_false
      @subscription.status.should == 'canceled'
    end
  end
end
