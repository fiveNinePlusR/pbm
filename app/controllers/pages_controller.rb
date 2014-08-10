require 'pony'

class PagesController < ApplicationController
  def region
    @locations = Location.where('region_id = ?', @region.id)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

    cities = Hash.new
    location_types = Hash.new

    @locations.each do |l|
      location_copy = l.clone
      if (location_copy.location_type_id)
        location_types[location_copy.location_type_id] = location_copy
      end

      cities[l.city] = location_copy

      location_copy = nil
    end

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => location_types.values.collect { |l| l.location_type }.sort {|a,b| a.name <=> b.name},
      },
      'location' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => @locations.sort_by(&:name),
        'autocomplete' => 1,
      },
      'machine' => {
        'id'   => 'id',
        'name' => 'name_and_year',
        'search_collection' => @region.machines.sort_by(&:massaged_name),
        'autocomplete' => 1,
      },
      'zone' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Zone.where('region_id = ?', @region.id).order('name'),
      },
      'operator' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Operator.where('region_id = ?', @region.id).order('name'),
      },
      'city' => {
        'id'   => 'city',
        'name' => 'city',
        'search_collection' => cities.values.sort_by(&:city),
      }
    }

    render "#{@region.name}/region" if (lookup_context.find_all("#{@region.name}/region").any?)
  end

  def contact_sent
      return unless params['contact_msg']

      if (verify_recaptcha)
        flash.now[:alert] = "Thanks for contacting us!"
        Pony.mail(
          :to => @region.users.collect {|u| u.email},
          :from => 'admin@pinballmap.com',
          :subject => "PBM - Message from the #{@region.full_name} pinball map",
          :body => [params['contact_name'], params['contact_email'], params['contact_msg']].join("\n")
        )
      else
        flash.now[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
      end
  end

  def about
    @links = Hash.new
    @region.region_link_xrefs.each do |rlx|
      (@links[rlx.category || 'Uncategorized'] ||= []) << rlx
    end

    @top_machines = LocationMachineXref.region(@region.name).select("machine_id, count(*) as machine_count").group(:machine_id).order('machine_count desc').limit(10)

    render "#{@region.name}/about" if (lookup_context.find_all("#{@region.name}/about").any?)
  end

  def links
    redirect_to about_path
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def submitted_new_location
    if (verify_recaptcha)
      if (params['location_machines'].match('http://'))
        flash.now[:alert] = "This sort of seems like you are sending us spam. If that's not the case, please contact us via the about page."
      else
        flash.now[:alert] = "Thanks for entering that location. We'll get it in the system as soon as possible."

        send_new_location_notification(params, @region)
      end
    else
      flash.now[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
    end
  end

  def suggest_new_location
    @states = Location.where(['region_id = ?', @region.id]).collect {|r| r.state}.uniq.sort
  end

  def robots
    robots = File.read(Rails.root + 'public/robots.txt')
    render :text => robots, :layout => false, :content_type => "text/plain"
  end

  def apps
  end

  def app_support
  end

  def privacy
  end

  def contact
    redirect_to about_path
  end

  def home
    if (ENV['TWITTER_CONSUMER_KEY'] && ENV['TWITTER_CONSUMER_SECRET'] && ENV['TWITTER_OAUTH_TOKEN_SECRET'] && ENV['TWITTER_OAUTH_TOKEN'])
      begin
        client = Twitter::REST::Client.new do |config|
            config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
            config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
            config.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
            config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
        end
        @tweets = client.user_timeline("pinballmapcom", :count => 5)
      rescue Twitter::Error
        @tweets = []
      end
    else
      @tweets = []
    end

    @all_regions = Region.order('full_name')
    @region_data = regions_javascript_data(@all_regions)
  end

  def regions_javascript_data(regions)
    ids = Array.new
    lats = Array.new
    lons = Array.new
    contents = Array.new

    regions.each do |r|
      cloned_region = r.clone
      ids      << cloned_region.id
      lats     << cloned_region.lat
      lons     << cloned_region.lon
      contents << cloned_region.content_for_infowindow

      cloned_region = nil
    end

    [ids, lats, lons, contents]
  end
end
