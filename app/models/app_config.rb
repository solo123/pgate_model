class AppConfig < ApplicationRecord
  scope :show_order, -> {order(:group, :name)}

  def self.get(group, name)
    if r = AppConfig.find_by(group: group, name: name)
      r.val
    else
      nil
    end
  end

  def self.set(group, name, val)
    if r = AppConfig.find_by(group: group, name: name)
      r.update(val: val)
    else
      r = AppConfig.new(group: group, name: name, val: val)
      r.save
    end
  end
end
