ActiveAdmin.register Experience do

  permit_params :name, :address, :description, :ta_id, :published, :user_id, :private, :published_at, :created_at, :updated_at, :average_rating, :from_guest_comment, :must_see, :wikipedia_link, :timetospent, :nb_votes, :unesco, :thousand_places# etc...



  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #   permitted = [:permitted, :attributes]
  #   permitted << :other if resource.something?
  #   permitted
  # end


end
