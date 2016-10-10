class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  has_many :biz_errors, as: :error_source

end
