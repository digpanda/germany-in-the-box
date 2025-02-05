class OrderTracking
  include MongoidBase
  include Mongoid::Search

  strip_attributes

  # research system
  search_in :id, :c_at

  field :delivery_id, type: String
  field :delivery_provider, type: String # Postelbe, dhlde, ems
  field :state, type: Symbol, default: :new # [:new, :processing, :accepted, :problem, :signature_received, :signature_returned, :local_distribution, :returned]
  field :histories, type: Array # all the history of the tracking so far
  field :refreshed_at, type: Time

  belongs_to :order, inverse_of: :order_tracking
end
