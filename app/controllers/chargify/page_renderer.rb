class Chargify::PageRenderer < ParagraphRenderer

  features '/chargify/page_feature'

  paragraph :subscribe
  paragraph :edit, :ajax => true
  paragraph :cancel
  paragraph :view

  def subscribe
    @options = paragraph_options(:subscribe)

    @plans = ChargifyPlan.available_plan.find :all, :order => 'name'

    if editor?
      @subscription = ChargifySubscription.new
      @subscription.end_user_id = myself.id
      render_paragraph :feature => :chargify_page_subscribe
      return
    end

    # Check for an existing active subscription
    @subscription = ChargifySubscription.active_subscription.find_by_end_user_id myself.id
    if @subscription
      if @options.edit_page_id
        redirect_paragraph @options.edit_page_url
        return
      end

      render_paragraph :feature => :chargify_page_subscribe
      return
    end

    # Create a new subscription
    @subscription = ChargifySubscription.new
    @subscription.end_user_id = myself.id

    if request.post? && params[:subscription]
      @subscription.attributes = params[:subscription].slice(*ChargifySubscription.valid_params)
      if @subscription.subscribe
        paragraph_action(myself.action('/chargify/plan/subscribe', :target => @subscription))
        paragraph.run_triggered_actions(@subscription,'new_subscription',myself)

        if @options.success_page_id
          redirect_paragraph @options.success_page_url
          return
        end
      end
    end

    render_paragraph :feature => :chargify_page_subscribe
  end

  def edit
    @options = paragraph_options(:edit)

    require_js('prototype.js')

    @plans = ChargifyPlan.available_plan.find :all, :order => 'name'

    if editor?
      @subscription = self.fake_chargify_subscription
      render_paragraph :feature => :chargify_page_edit
      return
    end

    @subscription = ChargifySubscription.active_subscription.find_by_end_user_id(myself.id) || ChargifySubscription.new

    if request.post? && params[:subscription]
      @subscription.attributes = params[:subscription].slice(*ChargifySubscription.valid_params)

      if ajax?
        render_paragraph :feature => :chargify_page_edit
        return
      end

      if @subscription.edit
        paragraph_action(myself.action('/chargify/plan/edit', :target => @subscription))
        paragraph.run_triggered_actions(@subscription,'edit_subscription',myself)

        if @options.view_page_id
          redirect_paragraph @options.view_page_url
          return
        end
      end
    end

    render_paragraph :feature => :chargify_page_edit
  end

  def view
    @options = paragraph_options(:view)

    if editor?
      @subscription = self.fake_chargify_subscription
    else
      @subscription = ChargifySubscription.active_subscription.find_by_end_user_id(myself.id) || ChargifySubscription.new
    end

    render_paragraph :feature => :chargify_page_view
  end

  def cancel
    @options = paragraph_options(:cancel)

    if editor?
      @subscription = self.fake_chargify_subscription
      render_paragraph :feature => :chargify_page_cancel
      return
    end

    @subscription = ChargifySubscription.active_subscription.find_by_end_user_id(myself.id) || ChargifySubscription.new

    if request.post? && params[:subscription]
      if @subscription.cancel
        paragraph_action(myself.action('/chargify/plan/cancel', :target => @subscription))
        paragraph.run_triggered_actions(@subscription,'canceled_subscription',myself)

        if @options.canceled_page_id
          redirect_paragraph @options.canceled_page_url
          return
        end
      end
    end

    render_paragraph :feature => :chargify_page_cancel
  end

  protected

  def fake_chargify_subscription #:nodoc:
    plan = ChargifyPlan.available_plan.find :first
    subscription = ChargifySubscription.new :data => {}, :components => {}, :end_user_id => myself.id, :chargify_plan_id => plan.id, :status => 'valid', :state => 'active'
    subscription.id = 0
    subscription
  end
end
