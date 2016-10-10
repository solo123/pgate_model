class BizError < ActiveRecord::Base
  belongs_to :error_source, polymorphic: true, optional: true
end
