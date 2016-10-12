class PostDat < ActiveRecord::Base
  scope :show_order, -> {order('id desc')}

  belongs_to :sender, polymorphic: true, optional: true
end
