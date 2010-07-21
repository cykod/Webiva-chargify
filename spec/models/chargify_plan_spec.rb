require  File.expand_path(File.dirname(__FILE__)) + '/../chargify_spec_helper'

describe ChargifyPlan do

  reset_domain_tables :chargify_plan, :chargify_component

  it "should require a name" do
    plan = ChargifyPlan.new
    plan.valid?.should be_false
    plan.should have(1).error_on(:name)
  end

  it "should be able to create a plan with just a name" do
    plan = ChargifyPlan.create :name => 'Basic Plan'
    plan.id.should_not be_nil
  end

  it "should be able to test if a plan is available" do
    plan = ChargifyPlan.new :name => 'Basic Plan', :status => 'active'
    plan.available?.should be_true

    plan = ChargifyPlan.new :name => 'Basic Plan', :status => 'hidden'
    plan.available?.should be_true

    plan = ChargifyPlan.new :name => 'Basic Plan', :status => 'inactive'
    plan.available?.should be_false
  end

  it "should be able to create a plan from the chargify api" do
    data = {"product_family"=>{"name"=>"Plans", "handle"=>"basic-plan", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"Basic Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"basic-plan", "return_url"=>"", "price_in_cents"=>1500, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6666, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get setup now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"}

    plan = ChargifyPlan.push_product data
    plan.id.should_not be_nil
    plan.product_family_id.should == 2091
  end

  it "should be able to update a plan from the chargify api" do
    data = {"product_family"=>{"name"=>"Plans", "handle"=>"basic-plan", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"Basic Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"basic-plan", "return_url"=>"", "price_in_cents"=>1500, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6666, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get setup now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"}

    plan = ChargifyPlan.push_product data
    plan.id.should_not be_nil
    plan_id = plan.id
    plan.product_family_id.should == 2091

    data = {"product_family"=>{"name"=>"Plans", "handle"=>"basic-plan", "accounting_code"=>nil, "id"=>2091, "description"=>""}, "name"=>"My Basic Plan", "created_at"=>"2010-07-08T10:52:19-04:00", "return_params"=>"", "handle"=>"basic-plan", "return_url"=>"", "price_in_cents"=>1500, "accounting_code"=>"", "expiration_interval"=>nil, "expiration_interval_unit"=>"never", "trial_interval"=>nil, "updated_at"=>"2010-07-08T10:52:19-04:00", "id"=>6666, "initial_charge_in_cents"=>500, "require_credit_card"=>true, "interval"=>1, "trial_price_in_cents"=>0, "description"=>"Get setup now.", "request_credit_card"=>true, "archived_at"=>nil, "trial_interval_unit"=>"month", "interval_unit"=>"month"}

    plan = ChargifyPlan.push_product data
    plan.id.should == plan_id
    plan.name.should == 'My Basic Plan'
    plan.product_family_id.should == 2091
  end

  describe "Handler" do
    class ChargifySpecTestPlanHandler < Chargify::PlanHandler
      def subscribe(product_identifier,components = {}); end
      def cancel(); end
      def edit(product_identifier,components = {}); end
      def can_edit?(product_identifier,components = {}); true; end
    end

    reset_domain_tables :end_user

    it "should be able to create the handle object" do
      user = EndUser.push_target 'test_user1@test.dev'
      plan = ChargifyPlan.create :name => 'Basic Plan', :status => 'active', :handler => ChargifySpecTestPlanHandler.to_s.underscore
      plan.should_receive(:get_handler_info).with(:chargify, :plan, ChargifySpecTestPlanHandler.to_s.underscore).once.and_return({:name => 'Test', :class => ChargifySpecTestPlanHandler})

      plan.handler_class.should == ChargifySpecTestPlanHandler
      plan.handler_info[:name].should == 'Test'
      handler = plan.handler_obj(user)
      handler.should_not be_nil
      handler.subscribe plan.product_handle
      handler.cancel
      handler.can_edit?(plan.product_handle).should be_true
      handler.edit plan.product_handle

      plan.handler = ''
      plan.save
      plan.handler.should be_nil
    end
  end
end
