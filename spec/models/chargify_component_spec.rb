require  File.expand_path(File.dirname(__FILE__)) + '/../chargify_spec_helper'

describe ChargifyComponent do

  reset_domain_tables :chargify_plan, :chargify_component

  it "should require a name" do
    component = ChargifyComponent.new
    component.valid?.should be_false
    component.should have(1).error_on(:name)
  end

  it "should be able to transform name" do
    component = ChargifyComponent.new :name => 'File storage'
    component.name.should == 'File storage'
    component.display_name.should == 'File storage'
    component.component_name.should == 'file_storage'
  end

  it "should be able to remove the plan name while transforming the name" do
    plan = ChargifyPlan.create :name => 'Basic Plan'
    plan.id.should_not be_nil
    component = ChargifyComponent.create :name => 'Basic Plan File storage', :chargify_plan_id => plan.id
    component.id.should_not be_nil
    component.name.should == 'Basic Plan File storage'
    component.display_name.should == 'File storage'
    component.component_name.should == 'basic_plan_file_storage'
  end

  it "should be able to create a component from chargify api hash" do
    [{"kind"=>"quantity_based_component", "name"=>"File storage", "created_at"=>"2010-07-08T12:51:06-04:00", "updated_at"=>"2010-07-08T12:51:06-04:00", "id"=>772, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"GB"}, {"kind"=>"quantity_based_component", "name"=>"Domains", "created_at"=>"2010-07-08T12:57:51-04:00", "updated_at"=>"2010-07-08T12:57:51-04:00", "id"=>773, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"domain"}, {"kind"=>"quantity_based_component", "name"=>"Client Users", "created_at"=>"2010-07-08T13:00:57-04:00", "updated_at"=>"2010-07-08T13:00:57-04:00", "id"=>774, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"client user"}].each do |data|
      component = ChargifyComponent.push_component 2091, data
      component.id.should_not be_nil
    end
  end

  it "should be able to update a component from the chargify api hash" do
    data = {"kind"=>"quantity_based_component", "name"=>"File storage", "created_at"=>"2010-07-08T12:51:06-04:00", "updated_at"=>"2010-07-08T12:51:06-04:00", "id"=>772, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"GB"}
    component = ChargifyComponent.push_component 2091, data
    component.id.should_not be_nil
    component_id = component.id

    data = {"kind"=>"quantity_based_component", "name"=>"Additional file storage", "created_at"=>"2010-07-08T12:51:06-04:00", "updated_at"=>"2010-07-08T12:51:06-04:00", "id"=>772, "pricing_scheme"=>"volume", "product_family_id"=>2091, "price_per_unit_in_cents"=>nil, "unit_name"=>"GB"}
    component = ChargifyComponent.push_component 2091, data
    component.id.should == component_id
    component.name.should == 'Additional file storage'
  end
end
