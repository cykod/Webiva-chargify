class Chargify::PageFeature < ParagraphFeature

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::FormTagHelper

  feature :chargify_page_subscribe, :default_feature => <<-FEATURE
  <cms:subscription>
    <cms:form>
      <cms:errors><div class='errors'><cms:value/></div></cms:errors>
      Plan: <cms:product_handle/><br/>
      First Name: <cms:billing_first_name/><br/>
      Last Name: <cms:billing_last_name/><br/>
      Address: <cms:billing_address/><br/>
      City: <cms:billing_city/><br/>
      State: <cms:billing_state/><br/>
      Zip: <cms:billing_zip/><br/>
      Country: <cms:billing_country/><br/>
      Credit Card: <cms:credit_card/><br/>
      Expires: <cms:expiration_month/> <cms:expiration_year/><br/>
      CVV: <cms:cvv/><br/>
      Coupon: <cms:coupon_code/><br/>
      <cms:submit/>
    </cms:form>
    <cms:active>
      <p>You subscription is ready.</p>
    </cms:active>
  </cms:subscription>
  FEATURE

  def chargify_page_subscribe_feature(data)
    webiva_feature(:chargify_page_subscribe,data) do |c|
      c.expansion_tag('subscription') { |t| data[:subscription] }
      c.form_for_tag('subscription:form','subscription') { |t| t.locals.subscription = data[:subscription] unless data[:subscription].id }
      c.field_tag('subscription:form:coupon_code')
      self.subscription_form_tags(c, data)
      c.expansion_tag('subscription:active') { |t| data[:subscription].id && data[:subscription].status == 'valid' }
    end
  end

  feature :chargify_page_edit, :default_feature => <<-FEATURE
  <cms:subscription>
    <div id="subscription_plans">
    <cms:plan>
      <p><cms:name/></p>
    </cms:plan>
    <cms:form>
      Plan: <cms:product_handle/><br/>
      First Name: <cms:billing_first_name/><br/>
      Last Name: <cms:billing_last_name/><br/>
      Address: <cms:billing_address/><br/>
      City: <cms:billing_city/><br/>
      State: <cms:billing_state/><br/>
      Zip: <cms:billing_zip/><br/>
      Country: <cms:billing_country/><br/>
      Credit Card: <cms:credit_card/> <cms:masked_card_number/><br/>
      Expires: <cms:expiration_month/> <cms:expiration_year/><br/>
      CVV: <cms:cvv/><br/>

      <cms:components>
        Components<br/>
        <cms:component>
          <cms:name/>: <cms:quantity/><br/>
        </cms:component>
      </cms:components>

      <cms:submit/>
    </cms:form>
    </div>
  </cms:subscription>
  FEATURE

  def chargify_page_edit_feature(data)
    webiva_feature(:chargify_page_edit,data) do |c|
      c.expansion_tag('subscription') { |t| t.locals.subscription = data[:subscription] if data[:subscription].id }
      c.form_for_tag('subscription:form','subscription', :html => {:id => 'subscription_plans_form'}) { |t| t.locals.subscription = data[:subscription] if data[:subscription].id }
      self.subscription_form_tags(c, data)
      self.subscription_features(c, data)
      c.field_tag("subscription:form:product_handle", :control => 'select', :options => data[:plans].collect{|p| [p.name, p.product_handle]}, :onchange => remote_function(:update => 'subscription_plans', :url => renderer.ajax_url, :method => 'post', :submit => 'subscription_plans_form'))
    end
  end

  feature :chargify_page_view, :default_feature => <<-FEATURE
  <cms:subscription>
    <cms:plan>
      <p><cms:name/></p>
    </cms:plan>
    <cms:components>
      <cms:component>
        <cms:name/>: <cms:quantity/><br/>
      </cms:component>
    </cms:components>
    <cms:transactions>
      <table>
        <tr><th>Id</th><th>Type</th><th>Memo</th><th>Amount</th><th>Successful</th><th>Occurred</th></tr>
      <cms:transaction>
        <tr>
            <td>#<cms:id/></td>
            <td><cms:type/></td>
            <td><cms:memo/></td>
            <td><cms:amount/></td>
            <td><cms:success>Yes</cms:success><cms:not_success>No</cms:not_success></td>
            <td><cms:created_at/></td>
        </tr>
      </cms:transaction>
      </table>
    </cms:transactions>
  </cms:subscription>
  FEATURE

  def chargify_page_view_feature(data)
    webiva_feature(:chargify_page_view,data) do |c|
      c.expansion_tag('subscription') { |t| t.locals.subscription = data[:subscription] if data[:subscription].id }
      self.subscription_features(c, data)
    end
  end

  feature :chargify_page_cancel, :default_feature => <<-FEATURE
  <cms:subscription>
    <cms:form>
      <cms:submit/>
    </cms:form>
    <cms:canceled>
      <p>Your plan has been canceled.</p>
    </cms:canceled>
  </cms:subscription>
  FEATURE

  def chargify_page_cancel_feature(data)
    webiva_feature(:chargify_page_cancel,data) do |c|
      c.expansion_tag('subscription') { |t| t.locals.subscription = data[:subscription] if data[:subscription].id }
      c.form_for_tag('subscription:form','subscription') do |t|
        if data[:subscription].id && data[:subscription].status == 'valid'
          t.locals.subscription = data[:subscription]
          { :code => hidden_field_tag('subscription[commit]',1) }
        end
      end
      c.submit_tag("subscription:form:submit", :default => 'Cancel Subscription')
      self.subscription_features(c, data)
    end
  end

  def subscription_form_tags(context, data, base='subscription:form')
    context.form_error_tag("#{base}:errors")
    context.field_tag("#{base}:billing_first_name")
    context.field_tag("#{base}:billing_last_name")
    context.field_tag("#{base}:credit_card")
    context.field_tag("#{base}:cvv")
    context.field_tag("#{base}:billing_address")
    context.field_tag("#{base}:billing_city")
    context.field_tag("#{base}:billing_state", :control => 'select', :options => Content::CoreField::UsStateField.states_select_options)
    context.field_tag("#{base}:billing_zip")
    context.field_tag("#{base}:billing_country") # 2 letter code
    context.field_tag("#{base}:expiration_month", :control => 'select', :options => (1..12).to_a)
    context.field_tag("#{base}:expiration_year", :control => 'select', :options => (Time.now.year..(Time.now.year+10)).to_a)
    context.field_tag("#{base}:product_handle", :control => 'select', :options => data[:plans].collect{|p| [p.name, p.product_handle]})
    context.submit_tag("#{base}:submit", :default => 'Submit')

    context.define_tag("#{base}:radio") do |t|
      plan = data[:plans].find { |p| p.product_handle == t.attr['name'] }
      if plan
        radio_button_tag('subscription[product_handle]', plan.product_handle, t.locals.subscription.product_handle == plan.product_handle)
      else
        'Invalid plan'
      end
    end

    context.loop_tag("#{base}:plan") { |t| data[:plans] }
    context.field_tag("#{base}:plan:product_handle", :control => :radio_buttons) { |t| [[t.locals.plan.name, t.locals.plan.product_handle]] }
    self.plan_features(context, data, "#{base}:plan")
    
    data[:plans].each do |plan|
      tag_name = plan.product_handle.downcase.gsub(/[^a-z0-9-]/, '').gsub('-', '_')
      context.expansion_tag("#{base}:#{tag_name}") { |t| t.locals.plan = plan }
      context.field_tag("#{base}:#{tag_name}:product_handle", :control => :radio_buttons) { |t| [[t.locals.plan.name, t.locals.plan.product_handle]] }
      self.plan_features(context, data, "#{base}:#{tag_name}")
    end

    context.loop_tag("#{base}:component") { |t| t.locals.subscription.chargify_components if t.locals.subscription.chargify_plan }
    self.component_form_tags(context, data, "#{base}:component")
  end

  def component_form_tags(context, data, base='subscription:form:component')
    context.define_tag("#{base}:quantity") do |t|
      text_field_tag "subscription[components][#{t.locals.component.component_name}]", t.locals.component.quantity
    end
    context.h_tag("#{base}:name") { |t| t.locals.component.display_name }
  end

  def component_features(context, data, base='component')
    context.value_tag("#{base}:quantity") { |t| t.locals.subscription.component_quantity(t.locals.component.component_id) }
    context.h_tag("#{base}:name") { |t| t.locals.component.display_name }
  end

  def subscription_features(context, data, base='subscription')
    context.h_tag("#{base}:card_type") { |t| t.locals.subscription.card_type }
    context.h_tag("#{base}:masked_card_number") { |t| t.locals.subscription.masked_card_number }
    context.h_tag("#{base}:expiration_month") { |t| t.locals.subscription.expiration_month }
    context.h_tag("#{base}:expiration_year") { |t| t.locals.subscription.expiration_year }
    context.h_tag("#{base}:billing_first_name") { |t| t.locals.subscription.billing_first_name }
    context.h_tag("#{base}:billing_last_name") { |t| t.locals.subscription.billing_last_name }
    context.h_tag("#{base}:billing_address") { |t| t.locals.subscription.billing_address }
    context.h_tag("#{base}:billing_city") { |t| t.locals.subscription.billing_city }
    context.h_tag("#{base}:billing_state") { |t| t.locals.subscription.billing_state }
    context.h_tag("#{base}:billing_zip") { |t| t.locals.subscription.billing_zip }
    context.h_tag("#{base}:billing_country") { |t| t.locals.subscription.billing_country }

    context.expansion_tag("#{base}:canceled") { |t| t.locals.subscription.status == 'canceled' }
    context.expansion_tag("#{base}:active") { |t| t.locals.subscription.status == 'valid' }

    context.expansion_tag("#{base}:plan") { |t| t.locals.plan = t.locals.subscription.chargify_plan }
    self.plan_features(context, data, "#{base}:plan")

    context.loop_tag("#{base}:transaction") { |t| t.locals.subscription.chargify_transactions }
    self.transaction_feature(context, data, "#{base}:transaction")

    context.loop_tag("#{base}:component") { |t| t.locals.subscription.chargify_plan.chargify_components if t.locals.subscription.chargify_plan }
    self.component_features(context, data, "#{base}:component")
  end

  def plan_features(context, data, base='plan')
    context.h_tag("#{base}:name") { |t| t.locals.plan.name }
    context.h_tag("#{base}:description") { |t| t.locals.plan.description }
  end

  def transaction_feature(context, data, base='transaction')
    context.value_tag("#{base}:id") { |t| t.locals.transaction.transaction_id }
    context.h_tag("#{base}:type") { |t| t.locals.transaction.charge_type.underscore.titleize }
    context.h_tag("#{base}:memo") { |t| t.locals.transaction.memo }
    context.value_tag("#{base}:amount") { |t| number_to_currency(t.locals.transaction.amount) }
    context.expansion_tag("#{base}:success") { |t| t.locals.transaction.success }
    context.date_tag("#{base}:created_at",DEFAULT_DATETIME_FORMAT.t) { |t| t.locals.transaction.created_at }
    context.value_tag("#{base}:created_ago") { |t| time_ago_in_words(t.locals.transaction.created_at) }
  end
end
