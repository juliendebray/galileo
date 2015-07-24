class Destination < ActiveRecord::Base
  has_many :recommended_trip_experiences
  has_many :recommended_trips
  has_many :experiences

  has_many :destination_pictures, dependent: :destroy
  accepts_nested_attributes_for :destination_pictures


  def slug
    I18n.transliterate(self.name.downcase.gsub("'","-").gsub(", ","-").gsub(" ", "-"))
  end

  def to_param
    "#{id}-#{slug}"
  end

end
