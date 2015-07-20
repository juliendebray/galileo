class RecommendedTripsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_trip, except: [:show]
  before_action :set_recommended_trip, except: [:show]
  respond_to :js, except: [:show]

  def add_to_trip
    order = @trip.trip_experiences.count + 1
    @recommended_trip.recommended_trip_experiences.each do |rte|
      @trip.trip_experiences.create(recommended_trip_id: @recommended_trip.id, experience_id: rte.experience.id, order: rte.order + order)
    end
  end

  def remove_from_trip
    @trip.trip_experiences.where(recommended_trip_id: @recommended_trip.id).delete_all
  end

  def show
    @recommended_trip = RecommendedTrip.find(params[:id])
  end

  private
  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def set_recommended_trip
    @recommended_trip = RecommendedTrip.find(params[:recommended_trip_id])
  end
end
