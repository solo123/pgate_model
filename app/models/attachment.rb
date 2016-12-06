class Attachment < ApplicationRecord
  belongs_to :attach_owner, polymorphic: true
  mount_uploader :attach_asset, AssetUploader
  # don't forget those if you use :attr_accessible (delete method and form caching method are provided by Carrierwave and used by RailsAdmin)
  attr_accessor :asset, :asset_cache, :remove_asset
  def tag_name_enum
    {
      '营业执照': 'lics',
      '身份证正面': 'pid_front', '身份证背面': 'pid_back',
      '手持身份证': 'pid_in_hand',
      '店铺门头': 'shop_front',
      '开户许可证': 'acct_lics'
    }
  end

end
