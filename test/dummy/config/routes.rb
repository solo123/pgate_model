Rails.application.routes.draw do
  mount PgateModel::Engine => "/pgate_model"
end
