class UserSubmissionsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @user_submission = UserSubmission.new(user_submission_params)
    if @user_submission.save
      redirect_to @user_submission, notice: 'UserSubmission was successfully created.'
    else
      render action: 'new'
    end
  end

  def list_within_range

    if params[:submission_type]
      user_submissions = UserSubmission.where.not(lat: nil)
                                       .where(created_at: min_date_of_submission..Date.today.end_of_day, submission_type: params[:submission_type])
                                       .near([params[:lat], params[:lon]], max_distance, order: false)
    else
      user_submissions = UserSubmission.where.not(lat: nil)
                                       .where(created_at: min_date_of_submission..Date.today.end_of_day)
                                       .near([params[:lat], params[:lon]], max_distance, order: false)
    end

    sorted_submissions = user_submissions.order('created_at DESC')
    render partial: "locations/recent_activity", locals: { sorted_submissions: sorted_submissions }
  end

  private

  def user_submission_params
    params.require(:user_submission).permit(:region_id, :user, :user_name, :user_id, :submission_type, :submission, :location, :lat, :lon, :location_name, :location_id, :city_name, :comment, :high_score, :machine, :machine_id, :machine_name)
  end
end
