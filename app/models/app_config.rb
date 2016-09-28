class AppConfig < ApplicationRecord
  scope :show_order, -> {order(:group)}

  def self.get(key)
    if r = AppConfig.find_by(group: key)
      r.val
    else
      nil
    end
  end

  def self.set(key, val)
    if r = AppConfig.find_by(group: key)
      r.update(val: val)
    else
      r = AppConfig.new(group: key, val: val)
      r.save
    end
  end
end
