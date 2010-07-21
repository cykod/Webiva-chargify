
class ChargifyTransaction < DomainModel
  belongs_to :chargify_subscription

  serialize :data

  validates_presence_of :chargify_subscription_id

  def memo
    self.data ? self.data['memo'] : nil
  end
end
