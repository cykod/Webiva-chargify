require  File.expand_path(File.dirname(__FILE__)) + "/../../../../spec/spec_helper"

class ChargifySpecTestPlanHandler < Chargify::PlanHandler
  def subscribe(product_identifier,components = {}); end
  def cancel(); end
  def edit(product_identifier,components = {}); end
  def can_edit?(product_identifier,components = {}); true; end
end

def fakeweb_chargify_customer_lookup(reference, body=nil)
  url = "https://fake:x@test.chargify.com/customers/lookup.json?reference=#{reference}"
  if body
    body = body.to_json unless body.is_a?(String)
    FakeWeb.register_uri :get, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
  else
    FakeWeb.register_uri :get, url, :status => ['404', 'Not found']
  end
end

def fakeweb_chargify_create_customer(body)
  url = "https://fake:x@test.chargify.com/customers.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :post, url, :status => ['201', 'Created'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_create_subscription(body)
  url = "https://fake:x@test.chargify.com/subscriptions.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :post, url, :status => ['201', 'Created'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_create_subscription_failure(body)
  url = "https://fake:x@test.chargify.com/subscriptions.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :post, url, :status => ['422', 'Failed'], :body => body, :content_type => 'application/jsonrequest'
end

def subscription_response(plan, user, customer_id=99, credit_card={})
  {
    "created_at"=>"2010-07-20T09:57:06-04:00",
    "activated_at"=>"2010-07-20T09:57:07-04:00",
    "expires_at"=>nil,
    "cancellation_message"=>nil,
    "trial_ended_at"=>nil,
    "updated_at"=>"2010-07-20T09:57:06-04:00",
    "credit_card"=>{"customer_vault_token"=>nil, "vault_token"=>"1", "card_type"=>"bogus", "current_vault"=>"bogus", "billing_state"=>'MA', "expiration_year"=>2011, "billing_city"=>'Charlestown', "billing_address_2"=>nil, "masked_card_number"=>"XXXX-XXXX-XXXX-1", "billing_address"=>'56 Rolland St', "expiration_month"=>10, "last_name"=>user.last_name, "billing_country"=>'US', "billing_zip"=>'02112', "first_name"=>user.first_name}.merge(credit_card),
    "id"=>82,
    "current_period_ends_at"=>"2010-08-20T10:02:30-04:00",
    "next_assessment_at"=>"2010-08-20T10:02:30-04:00",
    "product"=> plan.data,
    "customer"=>{"address"=>nil, "city"=>nil, "reference"=>"#{user.id}", "created_at"=>"2010-07-19T12:14:19-04:00", "zip"=>nil, "country"=>nil, "updated_at"=>"2010-07-19T12:14:19-04:00", "id"=>customer_id, "last_name"=>user.last_name, "address_2"=>nil, "phone"=>nil, "organization"=>nil, "email"=>user.email, "state"=>nil, "first_name"=>user.first_name},
    "current_period_started_at"=>"2010-07-20T10:02:30-04:00",
    "balance_in_cents"=>0,
    "state"=>"active"
  }
end

def fakeweb_chargify_edit_subscription_component(subscription_id, component_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}/components/#{component_id}.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :put, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_create_subscription_migration(subscription_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}/migrations.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :post, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_get_subscription(subscription_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :get, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_edit_subscription(subscription_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :put, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_edit_subscription_failure(subscription_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :put, url, :status => ['422', 'Failed'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_cancel_subscription(subscription_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}.json"
  body = body.to_json unless body.is_a?(String)
  FakeWeb.register_uri :delete, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
end

def fakeweb_chargify_get_coupon(product_family_id, code, body=nil)
  url = "https://fake:x@test.chargify.com/product_families/#{product_family_id}/coupons/find.json?code=#{code}"
  if body
    body = body.to_json unless body.is_a?(String)
    FakeWeb.register_uri :get, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
  else
    FakeWeb.register_uri :get, url, :status => ['404', 'Not found']
  end
end

def fakeweb_chargify_transactions(subscription_id, body)
  url = "https://fake:x@test.chargify.com/subscriptions/#{subscription_id}/transactions.json"
  body = body.collect{ |t| {:transaction => t} }.to_json unless body.is_a?(String)
  FakeWeb.register_uri :get, url, :status => ['200', 'Ok'], :body => body, :content_type => 'application/jsonrequest'
end

