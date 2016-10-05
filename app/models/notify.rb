class Notify < ApplicationRecord
  belongs_to :sender, polymorphic: true
end
