class RecommendedTrip < ActiveRecord::Base
  has_many :recommended_trip_experiences
  has_many :experiences, through: :recommended_trip_experiences
  belongs_to :destination

  has_attached_file :picture,
    styles: {
          banner: "851x440#",
          small: "260x174#",
          thumb: "160x100#",
    }

  validates_attachment_content_type :picture,
    content_type: /\Aimage\/.*\z/


  def slug
    I18n.transliterate(self.title.downcase.gsub("'","-").gsub(", ","-").gsub(" ", "-"))
  end

  def to_param
    "#{id}-#{slug}"
  end
end
