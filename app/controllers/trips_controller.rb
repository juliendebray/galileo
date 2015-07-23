class TripsController < ApplicationController
  before_action :authenticate_guest!, only: [:show_guest_user]
  before_action :authenticate_user!, except: [:update_order, :start, :inspiration, :explore_destination, :create, :show_guest_user, :notification_for_sharing_email, :providers]
  before_action :set_trip, only: [:start, :update, :show, :show_guest_user, :share_trip_email, :notification_for_sharing_email, :providers, :summarize, :update_order, :send_my_trip_email, :selection_display, :explore_map, :explore_destination]
  respond_to :js, only: [:selection_display, :share_trip_email]

  def create
    @trip = Trip.new(trip_params)
    @destination = Destination.find_by(country_code: @trip.country_code)
    if @destination && @trip.country_code
      redirect_to destination_path(@destination)
    else
      @trip.title = @trip.query
      @trip.save
      redirect_to inspiration_trip_path(@trip)
    end
  end

  def explore_map
    experiences = Experience.where(published: true, country_code: @trip.country_code)
    Destination.where(country_code: @trip.country_code).any? ? @destination = Destination.where(country_code: @trip.country_code).first : @destination = nil
    @markers = build_markers(experiences.sort_by{|e| e.average_rating}.reverse, @trip, false)
  end

  def explore_destination
    experiences = Experience.where(published: true, country_code: @trip.country_code)
    @destination = Destination.find_by(country_code: @trip.country_code)
    @trip.trip_experiences.where.not(recommended_trip_id: nil).any? ? @recommended_trip_id = @trip.trip_experiences.where.not(recommended_trip_id: nil).first.recommended_trip_id : @recommended_trip_id = nil
    @markers = build_markers(experiences.sort_by{|e| e.average_rating}.reverse, @trip, false)
  end

  def search_results
    @trip = Trip.find(params[:trip_id])
    # Experiences selection
    experiences_selection = Experience.where(published: true, country_code: @trip.country_code, landing_point: false)
    experiences_list = []
    if !(params[:categories].nil? || params[:categories].length == 5)
      if params[:categories].include?('must')
        experiences_list += (experiences_selection.where(must_see: true).to_a) if params[:categories].include?('must')
      end
      if params[:categories].include?('otbt')
        experiences_selection.each{|e| experiences_list << e if e.category_tab.to_a.include?('otbt')}
      end
      if params[:categories].include?('relax')
        experiences_selection.each{|e| experiences_list << e if e.category_tab.to_a.include?('relax')}
      end
      if params[:categories].include?('culture')
        puts 'CULTURE'
        experiences_selection.each{|e| experiences_list << e if e.category_tab.to_a.include?('culture')}
      end
      if params[:categories].include?('sport')
        puts 'SPORT'
        experiences_selection.each{|e| experiences_list << e if e.category_tab.to_a.include?('sport')}
      end
      if params[:categories].include?('nature')
        puts 'NATURE'
        experiences_selection.each{|e| experiences_list << e if e.category_tab.to_a.include?('nature')}
      end
      experiences_selection = experiences_list.uniq

      # Fetch experiences according to categories
      # if params[:categories].include?('must')
      #   formatted_categories = params[:categories] - ['must']
      #   experiences_selection = experiences_selection.where(must_see: true)
      #   if !(formatted_categories.empty?)
      #     # Fetch only must_see
      #     experiences_tmp = []


      #     experiences_selection.each do |experience|
      #       experiences_tmp << experience if (experience.category_tab.any?) && ((experience.category_tab.to_a - formatted_categories).length <= formatted_categories.length) && ((experience.category_tab.to_a - formatted_categories).length < experience.category_tab.to_a.length)
      #     end
      #    experiences_selection = experiences_tmp
      #   end
      # else
      #    experiences_tmp = []
      #    experiences_selection.each do |experience|
      #      experiences_tmp << experience if (experience.category_tab.any?) && ((experience.category_tab.to_a - params[:categories]).length <= params[:categories].length) && ((experience.category_tab.to_a - params[:categories]).length < experience.category_tab.to_a.length)
      #    end
      #   experiences_selection = experiences_tmp
      # end
    end
    @markers = build_markers(experiences_selection.sort_by{|e| e.average_rating}.reverse, @trip, false)
    render json: @markers
  end

  def search_results_with_block
    @trip = Trip.find(params[:trip_id])
    # Experiences selection
    experiences_selection = Experience.where(published: true, country_code: @trip.country_code)
    if !(params[:categories].nil? || params[:categories].length == 5)
      # Fetch experiences according to categories
      if params[:categories].include?('must')
        formatted_categories = params[:categories] - ['must']
        experiences_selection = experiences_selection.where(must_see: true)
        if !(formatted_categories.empty?)
          # Fetch only must_see
          experiences_tmp = []


          experiences_selection.each do |experience|
            experiences_tmp << experience if (experience.category_tab.any?) && ((experience.category_tab.to_a - formatted_categories).length <= formatted_categories.length) && ((experience.category_tab.to_a - formatted_categories).length < experience.category_tab.to_a.length)
          end
         experiences_selection = experiences_tmp
        end
      else
         experiences_tmp = []
         experiences_selection.each do |experience|
           experiences_tmp << experience if (experience.category_tab.any?) && ((experience.category_tab.to_a - params[:categories]).length <= params[:categories].length) && ((experience.category_tab.to_a - params[:categories]).length < experience.category_tab.to_a.length)
         end
        experiences_selection = experiences_tmp
      end
    end
    @markers = build_markers(experiences_selection.sort_by{|e| e.average_rating}.reverse, @trip, true)
    render json: @markers
  end


  def start
    @trip = Trip.find(params[:id])
    if current_user
      @trip.update(user_id: current_user.id) unless @trip.user
      redirect_to @trip
    elsif @trip.user
      redirect_to @trip
    else
      if TripExperience.find_by(trip_id: params[:id])
        @trip_exp_tab = @trip.trip_experiences.sort_by do |te|
          te.order
        end
      end
      render :show
    end
  end

  def update
    @trip.update(user_id: current_user.id)
    if params[:order]
      order_hash = JSON.parse(params[:order])
      update_trip_experience_order(order_hash)
    end
    flash[:sucess] = 'Voyage sauvegardé!'
    redirect_to trip_path(@trip)
  end

  def update_order
    if params[:order]
      order_hash = params[:order]
      update_trip_experience_order(order_hash)
    end
  end

  # Lebanes demo
  def selection_display
    @destination = Destination.first
  end

  def show
    @guest_user = false
    @trip = current_user.trips.find(params[:id])
    # set_orders_if_nil!(@trip.trip_experiences)
    @trip_exp_tab = @trip.trip_experiences.sort_by do |te|
      te.order
    end
    unless browser.mobile? || browser.tablet?
      redirect_to demo_trip_path(@trip)
    end
  end

  # Libanese demo - change for value proposition testing purpose
  def demo
    # @destination = Destination.first
    @trip = Trip.find(params[:id])
    @guest_user = false
    @trip_exp_tab = @trip.trip_experiences.sort_by do |te|
      te.order
    end
    if browser.mobile? || browser.tablet?
      redirect_to trip_path(@trip)
    end
  end

  def plan_my_trip
    @trip = Trip.find(params[:id])
    @guest_user = false
    @trip_exp_tab = @trip.trip_experiences.sort_by do |te|
      te.order
    end
    if browser.mobile? || browser.tablet?
      redirect_to trip_path(@trip)
    end
  end

  def inspiration
    @trip = Trip.find(params[:id])
    experiences = Experience.where(published: true, country_code: @trip.country_code)
    @markers = build_markers(experiences.sort_by{|e| e.average_rating}.reverse, @trip, true)
  end

  def summarize
    # set_orders_if_nil!(@trip.trip_experiences)
    @trip_exp_ordered = @trip.trip_experiences.sort_by do |te|
      te.order
    end
  end

  def show_guest_user
    if params[:token] == @trip.token
      @guest_user = true
      trip_experiences =  @trip.trip_experiences
      trip_exp_tab_all = trip_experiences.sort_by do |te|
        te.order
      end
      @trip_exp_tab = trip_exp_tab_all.reject { |te| te.experience.from_guest_comment == true }
    else
      render "public/422.html"
    end
  end

  def destroy
    trip = Trip.find(params[:id])
    trip.destroy
    redirect_to user_path(current_user)
  end

  def share_trip_email
    current_user.send_trip_email(@trip)
    # flash[:sucess] = 'Un email vous a été envoyé avec le lien vers votre voyage.'
    # redirect_to trip_ask_your_friends_path(@trip)
    # redirect_to session[:previous_url]
  end

  def notification_for_sharing_email
    @trip.user.send_notif_email(@trip)
    # TODO: check if hidden field in the form_for is really necessary
  end

  def send_my_trip_email
    current_user.send_trip_summary_email(@trip)
    flash[:sucess] = 'Un email vous a été envoyé avec le résumé de votre voyage.'
    redirect_to summarize_trip_path(@trip)
    # TODO: redirect to js to change the class of the button
    # TODO: check if hidden field in the form_for is really necessary
  end

  def providers
  end

  private

  def name_array(filters)
    name_array = []
    if filters.any?
      filters.each do |filter|
        name_array << filter.name
      end
    end
    return name_array
  end

  def trip_params
    params.require(:trip).permit(
      :query,
      :latitude,
      :longitude,
      :picture,
      :country_code,
      :vp_ne_lat,
      :vp_ne_lng,
      :vp_sw_lat,
      :vp_sw_lng,
      :title
    )
  end

  def set_trip
    @trip = Trip.find(params[:id])
  end

  def update_trip_experience_order(order_hash)
    order_hash.each do |k, v|
      TripExperience.find(v.to_i).update(order: k.to_i)
    end
  end

  def authenticate_guest!
    @trip = Trip.find(params[:id])
    @guest_user = true if @trip.token == params[:token]
  end

  def build_markers(experiences, trip, experience_block_required)
    Gmaps4rails.build_markers(experiences) do |experience, marker|
      marker.lat experience.latitude
      marker.lng experience.longitude
      marker.title experience.name
      if experience.landing_point
        picture_url = "https://philae-floju.s3.amazonaws.com/markers/airport_logo.png"
        marker.picture({
          url: picture_url,
          width:  25,
          height: 39
        })
      else
        experience.must_see ? picture_url = "https://philae-floju.s3.amazonaws.com/markers/top_must_see.png" : picture_url = "https://philae-floju.s3.amazonaws.com/markers/top_2.png"
        marker.picture({
          url: picture_url,
          width:  25,
          height: 39
        })
        if experience_block_required
          marker.json({
            infobox:  render_to_string(partial: "/trip_experiences/infowindow.html.erb", locals: {
              experience: experience,
              trip: trip,
              trip_experience: false,
              guest_user: false
            }),
            experience_id: experience.id,
            experience_block: render_to_string(partial: "/trip_experiences/experience_block.html.erb", locals: {
              trip_exp: false,
              guest_user: false,
              experience: experience,
              trip: trip
            })
          })
        else
          marker.json({
            infobox:  render_to_string(partial: "/trip_experiences/infowindow.html.erb", locals: {
              experience: experience,
              trip: trip,
              trip_experience: false,
              guest_user: false
            }),
            experience_id: experience.id,
          })
        end
      end
    end
  end
end
