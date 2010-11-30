require  File.expand_path(File.dirname(__FILE__)) + '/../../chargify_spec_helper'

describe Chargify::SubscriptionHandler do

  reset_domain_tables :chargify_plan, :chargify_component, :chargify_subscription, :end_user, :access_token, :end_user_token, :chargify_transaction, :shop_orders, :shop_order_items

  before(:each) do
    FakeWeb.allow_net_connect = false
    FakeWeb.clean_registry

    @token = AccessToken.create :token_name => 'Paid Member Subscription', :editor => 0, :description => ''
    @options = Chargify::SubscriptionHandler.handler_options
    @options.access_token_id = @token.id
    Configuration.set_config_model @options

    ChargifyPlan.should_receive(:get_handler_info).with(:chargify, :plan, Chargify::SubscriptionHandler.to_s.underscore, false).any_number_of_times.and_return({:name => 'Subscription Handler', :class => Chargify::SubscriptionHandler})

    @basic_plan = ChargifyPlan.push_product "product_family"=>{"name"=>"Plans", "handle"=>"plans", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"Basic Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"basic-plan", "return_url"=>"", "price_in_cents"=>1499, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6666, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get setup now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"
    @basic_plan.update_attributes :handler => Chargify::SubscriptionHandler.to_s.underscore, :status => 'active'

    @user = EndUser.push_target 'test_user1@test.dev', :first_name => 'Tester', :last_name => 'Last'

    @transactions = [{"created_at"=>"2010-07-21T12:36:39-04:00", "product_id"=>6666, "ending_balance_in_cents"=>0, "memo"=>"Bogus Gateway: Forced success", "id"=>839904, "amount_in_cents"=>1999, "type"=>"PaymentAuthorization", "subscription_id"=>82, "success"=>true}, {"created_at"=>"2010-07-21T12:36:38-04:00", "product_id"=>6666, "ending_balance_in_cents"=>1999, "memo"=>"Initial/Startup fees", "id"=>839902, "amount_in_cents"=>500, "type"=>"Charge", "subscription_id"=>82, "success"=>true}, {"created_at"=>"2010-07-21T12:36:38-04:00", "product_id"=>6666, "ending_balance_in_cents"=>1499, "memo"=>"Basic Plan (recurring charge)", "id"=>839901, "amount_in_cents"=>1499, "type"=>"Payment", "subscription_id"=>82, "success"=>true}]

    @client = Chargify::WebivaClient.new 'fake', 'test'
    @client.should_receive(:valid?).any_number_of_times.and_return(true)
    @options = Chargify::AdminController.module_options
    @options.should_receive(:client).any_number_of_times.and_return(@client)
    @options.api_key = 'fake'
    @options.subdomain = 'test'
    Configuration.set_config_model(@options)
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
      assert_difference 'EndUserToken.count', 1 do
        subscription.subscribe.should be_true
      end
      subscription.id.should_not be_nil
      subscription.product_family_id.should == @basic_plan.product_family_id

      eut = EndUserToken.find_by_end_user_id_and_access_token_id @user.id, @token.id
      eut.should_not be_nil
    end

  end

  describe "Canceling" do
    before(:each) do
      @user.add_token! @token
      data = subscription_response @basic_plan, @user
      @subscription = ChargifySubscription.create :chargify_plan_id => @basic_plan.id, :end_user_id => @user.id, :product_family_id => @basic_plan.product_family_id, :status => 'valid', :components => nil, :data => data, :state => data['state'], :subscription_id => data['id'], :activated_at => data['activated_at'], :expires_at => data['expires_at'], :created_at => data['created_at'], :updated_at => data['updated_at']
    end

    it "should be able to cancel a subscription" do
      fakeweb_chargify_cancel_subscription 82, :subscription => subscription_response(@basic_plan, @user)
      fakeweb_chargify_transactions 82, @transactions
      assert_difference 'EndUserToken.count', -1 do
        @subscription.cancel.should be_true
      end
      @subscription.status.should == 'canceled'
      eut = EndUserToken.find_by_end_user_id_and_access_token_id @user.id, @token.id
      eut.should be_nil
    end
  end
end
