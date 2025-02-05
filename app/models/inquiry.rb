require 'will_paginate/array'

class Inquiry
  include MongoidBase
  include Mongoid::Search

  # research system
  search_in :id, :status, user: :id, service: :name

  field :status, type: Symbol, default: :new # [:new, :replied, :confirmed, :rejected, :paid, :terminated]

  field :email, type: String
  field :mobile, type: String
  field :scheduled_for, type: Time
  field :comment, type: String
  field :raw_referrer, type: String # NOTE : this is temporary for the presentation

  belongs_to :user, inverse_of: :inquiries
  belongs_to :referrer, inverse_of: :inquiries
  belongs_to :service, inverse_of: :inquiries

  has_one :referrer_provision,    inverse_of: :inquiry,    dependent: :restrict
  has_many :notes, inverse_of: :inquiry,    dependent: :restrict

  scope :ongoing, -> { self.in(status: [:replied, :confirmed, :paid]) }

  validates :status, presence: true , inclusion: { in: [:new, :replied, :confirmed, :rejected, :paid, :terminated] }
end
