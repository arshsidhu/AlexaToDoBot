class Task
  include Mongoid::Document
  field :num, type: Integer
  field :user, type: String
  field :tag, type: String
  field :date, type: Time
  field :description, type: String

  validates :tag, presence: true
  validates :date, presence: true
  validates :description, presence: true, length: {minimum: 5}
end
