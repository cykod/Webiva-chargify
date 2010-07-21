require File.dirname(__FILE__) + "/../../../../../spec/spec_helper"

describe ActiveWebService do

  before(:each) do
    @service_class = Class.new ActiveWebService
    FakeWeb.allow_net_connect = false
  end

  class DummyProduct
    attr_accessor :data
    def initialize(resource)
      raise 'Missing id' unless resource['id']
      @data = resource
    end
  end

  def fakeweb_response(method, url, code, value)
    FakeWeb.clean_registry
    status = [code.to_s, 'Ok']
    FakeWeb.register_uri(method, url, :status => status, :body => value.to_json, :content_type => 'application/jsonrequest')
  end

  it "should build the url and options" do
    @service = @service_class.new
    @service.base_uri = 'http://test.dev'
    @service.basic_auth = {:username => 'user', :password => 'x'}

    @service.build_url('/items.json').should == 'http://test.dev/items.json'
    options = {}
    @service.build_options!(options)
    options.should == {:basic_auth => {:username => 'user', :password => 'x'}}

    options = {}
    fakeweb_response(:get, 'http://user:x@test.dev/items.json', 200, {})
    @service.request :get, '/items.json', options
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/items.json'
    @service.request_options.should == {:basic_auth => {:username => 'user', :password => 'x'}}
  end

  it "should be able to create a route using GET" do
    @service_class.route :products, '/products.json'
    @service_class.method_defined?(:products).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    fakeweb_response(:get, 'http://test.dev/products.json', 200,
                     [{'product' => {'id' => 1, 'name' => 'Item1'}}, {'product' => {'id' => 2, 'name' => 'Item2'}}])
    @service.products
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {}    
  end

  it "should be able to create a route using POST" do
    @service_class.route :create_product, '/products.json', :resource => 'product'
    @service_class.route :add_products, '/products.json'
    @service_class.method_defined?(:create_product).should be_true
    @service_class.method_defined?(:add_products).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Create
    fakeweb_response(:post, 'http://test.dev/products.json', 201, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.create_product :name => 'Item1'
    @service.request_method.should == :post
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item1'}}}

    # Add
    fakeweb_response(:post, 'http://test.dev/products.json', 201, {'product' => {'id' => 2, 'name' => 'Item2'}})
    @service.add_products 'product' => {:name => 'Item2'}
    @service.request_method.should == :post
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item2'}}}
  end

  it "should be able to create a route using PUT" do
    @service_class.route :edit_product, '/products/:product_id.json', :resource => 'product'
    @service_class.route :update_products, '/products/:product_id.json'
    @service_class.method_defined?(:edit_product).should be_true
    @service_class.method_defined?(:update_products).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Edit
    fakeweb_response(:put, 'http://test.dev/products/1.json', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.edit_product 1, :name => 'Item1'
    @service.request_method.should == :put
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item1'}}}

    # Update
    fakeweb_response(:put, 'http://test.dev/products/2.json', 200, {'product' => {'id' => 2, 'name' => 'Item2'}})
    @service.update_products 2, 'product' => {:name => 'Item2'}
    @service.request_method.should == :put
    @service.request_url.should == 'http://test.dev/products/2.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item2'}}}
  end

  it "should be able to create a route using DELETE" do
    @service_class.route :delete_product, '/products/:product_id.json'
    @service_class.method_defined?(:delete_product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Delete
    fakeweb_response(:delete, 'http://test.dev/products/1.json', 200, {})
    @service.delete_product 1
    @service.request_method.should == :delete
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {}
  end

  it "should be able to setup RESTful routes" do
    @service_class.rest :product, :products, '/products.json'
    @service_class.method_defined?(:products).should be_true
    @service_class.method_defined?(:product).should be_true
    @service_class.method_defined?(:create_product).should be_true
    @service_class.method_defined?(:edit_product).should be_true
    @service_class.method_defined?(:delete_product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Get products
    fakeweb_response(:get, 'http://test.dev/products.json', 200,
                                [{'product' => {'id' => 1, 'name' => 'Item1'}},{'product' => {'id' => 2, 'name' => 'Item2'}}])
    @service.products
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {}    

    # Get a product
    fakeweb_response(:get, 'http://test.dev/products/1.json', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.product 1
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {}    

    # Create
    fakeweb_response(:post, 'http://test.dev/products.json', 201, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.create_product :name => 'Item1'
    @service.request_method.should == :post
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item1'}}}

    # Edit
    fakeweb_response(:put, 'http://test.dev/products/1.json', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.edit_product 1, :name => 'Item1'
    @service.request_method.should == :put
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item1'}}}

    # Delete
    fakeweb_response(:delete, 'http://test.dev/products/1.json', 200, {})
    @service.delete_product 1
    @service.request_method.should == :delete
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {}
  end

  it "should be able to save resources" do
    @service_class.rest :product, :products, '/products.json'
    @service_class.method_defined?(:create_product).should be_true
    @service_class.method_defined?(:edit_product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Create
    fakeweb_response(:post, 'http://test.dev/products.json', 201, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.save :product, :name => 'Item1'
    @service.request_method.should == :post
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {:body => {'product' => {:name => 'Item1'}}}

    # Edit
    fakeweb_response(:put, 'http://test.dev/products/1.json', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.save :product, :id => 1, :name => 'Item1'
    @service.request_method.should == :put
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {:body => {'product' => {:id => 1, :name => 'Item1'}}}
  end

  it "should be able to change the return value using a class" do
    @service_class.rest :product, :products, '/products.json', :return => DummyProduct
    @service_class.method_defined?(:products).should be_true
    @service_class.method_defined?(:product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Get products
    fakeweb_response(:get, 'http://test.dev/products.json', 200,
                                [{'product' => {'id' => 1, 'name' => 'Item1'}}, {'product' => {'id' => 2, 'name' => 'Item2'}}])
    products = @service.products
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {}    
    products.is_a?(Array).should be_true
    products[1].data['id'].should == 2

    # Get a product
    fakeweb_response(:get, 'http://test.dev/products/1.json', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    product = @service.product 1
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {}    
    product.is_a?(DummyProduct).should be_true
    product.data['id'].should == 1
  end

  it "should be able to change the return value using a function" do
    @service_class.send(:define_method, :handle_product) { |resource| resource['name'] }
    @service_class.rest :product, :products, '/products.json', :return => :handle_product
    @service_class.method_defined?(:products).should be_true
    @service_class.method_defined?(:product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Get products
    fakeweb_response(:get, 'http://test.dev/products.json', 200, [{'product' => {'id' => 1, 'name' => 'Item1'}},
                                   {'product' => {'id' => 2, 'name' => 'Item2'}}])
    products = @service.products
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products.json'
    @service.request_options.should == {}    
    products.is_a?(Array).should be_true
    products.should == ['Item1', 'Item2']

    # Get a product
    fakeweb_response(:get, 'http://test.dev/products/1.json', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    product = @service.product 1
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {}    
    product.is_a?(String).should be_true
    product.should == 'Item1'
  end

  it "should be able to use a find_<resource> method to adjust the query option" do
    @service_class.route :find_product, '/products/lookup.json', :resource => 'product'
    @service_class.route :find_component, '/products/:product_id/components/lookup.json', :resource => 'component'
    @service_class.method_defined?(:find_product).should be_true
    @service_class.method_defined?(:find_component).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Get a product
    fakeweb_response(:get, 'http://test.dev/products/lookup.json?name=Item1', 200, {'product' => {'id' => 1, 'name' => 'Item1'}})
    @service.find_product_by_name 'Item1'
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products/lookup.json'
    @service.request_options.should == {:query => {'name' => 'Item1'}}

    # Get a component
    fakeweb_response(:get, 'http://test.dev/products/1/components/lookup.json?name=C2', 200, {'component' => {'id' => 100, 'name' => 'C2'}})
    @service.find_component_by_name 1, 'C2'
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products/1/components/lookup.json'
    @service.request_options.should == {:query => {'name' => 'C2'}}
  end

  it "should raise invalid response" do
    @service_class.rest :product, :products, '/products.json'
    @service_class.method_defined?(:product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    # Get a product
    fakeweb_response(:get, 'http://test.dev/products/1.json', 400, {})
    lambda{ @service.product 1 }.should raise_error(ActiveWebService::InvalidResponse)
    @service.request_method.should == :get
    @service.request_url.should == 'http://test.dev/products/1.json'
    @service.request_options.should == {}
  end

  it "should raise error if find function is not found" do
    @service_class.route :find_product, '/products/lookup.json', :resource => 'product'
    @service_class.method_defined?(:find_product).should be_true

    @service = @service_class.new
    @service.base_uri = 'http://test.dev'

    lambda{ @service.find_component_by_name 'Item1' }.should raise_error(ActiveWebService::MethodMissing)
    lambda{ @service.save :product, {:name => 'Item1'} }.should raise_error(ActiveWebService::MethodMissing)
    lambda{ @service.save :product, {:id => 1, :name => 'Item1'} }.should raise_error(ActiveWebService::MethodMissing)
  end

end
