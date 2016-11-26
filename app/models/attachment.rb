class Attachment < ApplicationRecord
  belongs_to :attach_owner, polymorphic: true
  mount_uploader :attach_asset, AssetUploader
  # don't forget those if you use :attr_accessible (delete method and form caching method are provided by Carrierwave and used by RailsAdmin)
  attr_accessor :asset, :asset_cache, :remove_asset

end
