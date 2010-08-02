class Chargify::PageController < ParagraphController

  editor_header 'Chargify Paragraphs'
  
  editor_for :subscribe, :name => "Subscribe", :feature => :chargify_page_subscribe,
    :triggers => [['New Subscription', 'new_subscription']]

  editor_for :edit, :name => "Edit", :feature => :chargify_page_edit,
    :triggers => [['Edit Subscription', 'edit_subscription']]

  editor_for :view, :name => "View", :feature => :chargify_page_view

  editor_for :cancel, :name => "Cancel", :feature => :chargify_page_cancel,
    :triggers => [['Canceled Subscription', 'canceled_subscription']]

  class SubscribeOptions < HashModel
    attributes :success_page_id => nil, :edit_page_id => nil

    page_options :success_page_id, :edit_page_id

    options_form(
                 fld(:success_page_id, :page_selector),
                 fld(:edit_page_id, :page_selector)
                 )

    def options_partial
      "/application/triggered_options_partial"
    end
  end

  class EditOptions < HashModel
    attributes :view_page_id => nil, :cancel_page_id => nil

    page_options :view_page_id, :cancel_page_id

    options_form(
                 fld(:view_page_id, :page_selector),
                 fld(:cancel_page_id, :page_selector)
                 )

    def options_partial
      "/application/triggered_options_partial"
    end
  end

  class ViewOptions < HashModel
    attributes :edit_page_id => nil, :cancel_page_id => nil

    page_options :edit_page_id, :cancel_page_id

    options_form(
                 fld(:edit_page_id, :page_selector),
                 fld(:cancel_page_id, :page_selector)
                 )
  end

  class CancelOptions < HashModel
    attributes :edit_page_id => nil, :view_page_id => nil, :canceled_page_id => nil

    page_options :edit_page_id, :view_page_id, :canceled_page_id

    options_form(
                 fld(:canceled_page_id, :page_selector),
                 fld(:edit_page_id, :page_selector),
                 fld(:view_page_id, :page_selector)
                 )

    def options_partial
      "/application/triggered_options_partial"
    end
  end
end
