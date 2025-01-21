ActiveAdmin.register Rent do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :unit_id, :tenant_id, :amount, :payment_date, :status, :is_advance
  #
  # or
  #
  # permit_params do
  #   permitted = [:unit_id, :tenant_id, :amount, :payment_date, :status, :is_advance]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  belongs_to :tenant
end
