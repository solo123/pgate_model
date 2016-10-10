class PostData < ActiveRecord::Base
  belongs_to :sender, polymorphic: true, optional: true
end
