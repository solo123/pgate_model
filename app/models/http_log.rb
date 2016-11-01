class HttpLog < ApplicationRecord
  belongs_to :sender, polymorphic: true, optional: true
end
