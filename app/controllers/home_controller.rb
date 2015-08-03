class HomeController < ApplicationController
  def index
    version = '1.0'
    @version = Rails.env.production? ? version : "#{version} ALPHA"
    @username =  "SLIM User"
    @lipids_count = Lipid.count
    @features_count = Feature.count
    @oxichain_count = ActiveRecord::Base.connection.execute('SELECT max(`oxichain`) from `features`')
    @oxichain_count = @oxichain_count.first
    @oxichain_count = @oxichain_count[0] ? @oxichain_count[0] : '-'
    @samples_count = Sample.count
    @groups_count = Group.count
  end
  def clear_sessions
    reset_session
    render :text => 'clear sessions'
  end
end
