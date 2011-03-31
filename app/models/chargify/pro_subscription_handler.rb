
class Chargify::ProSubscriptionHandler < Chargify::PlanHandler

  def self.chargify_plan_handler_info
    {
      :name => 'Pro Subscription Handler'
    }
  end

  def subscribe(product_identifier, components={})
    return unless self.token
    self.user.add_token!(self.token, :valid_until => nil, :valid_at => nil) if self.token
  end

  def cancel
    return unless self.token
    end_user_token = EndUserToken.find_by_end_user_id_and_access_token_id self.user.id, self.token.id
    end_user_token.destroy if end_user_token
  end

  def can_edit?(product_identifier, components={})
    false
  end

  def token
    Chargify::SubscriptionHandler.handler_options.pro_access_token
  end

  def self.handler_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  class Options < HashModel
    attributes :pro_access_token_id => nil

    validates_presence_of :pro_access_token_id

    options_form(
                 fld(:pro_access_token_id, :select, :options => :access_token_options, :description => "Token to added to the user when they subscribe. Use this token when\nsetting up the lock(s) for the paid member section of your site.")
                 )

    def validate
      self.errors.add(:pro_access_token_id, 'is invalid') if self.pro_access_token_id && self.pro_access_token.nil?
    end

    def pro_access_token
      @access_token ||= AccessToken.find_by_id self.pro_access_token_id
    end

    def access_token_options
      options = AccessToken.select_options_with_nil nil, :conditions => {:editor => 0}
      if options.length == 1
        AccessToken.create :token_name => 'Pro Paid Member Subscription', :editor => 0, :description => ''
        options = AccessToken.select_options_with_nil nil, :conditions => {:editor => 0}
      end
      options
    end
  end
end
