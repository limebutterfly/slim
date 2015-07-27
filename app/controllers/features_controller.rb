class FeaturesController < ApplicationController
  include ActionController::Live

  def index
    @features_count = Feature.count
    @features = Feature.page params[:page]
    @page = params[:page]
    if @page
      @start = 300*(@page.to_i-1)+1
    else
      @start = 1
    end
    @end = if @features_count < @start+300
             @features_count
           else
             @start + 300 - 1
           end
    @idents= {}
    @features.each do |feature|
       @idents[feature.id] = 0
    end
    unless @idents.keys.count == 0
      ActiveRecord::Base.connection.execute('SELECT feature_id FROM identifications WHERE feature_id IN (%s)'%@idents.keys.join(",")).each do |id|
        @idents[id[0].to_i] += 1
      end
    end
  end

  def plot_2d
  end

  def load_features
    response.headers['Content-Type'] = 'text/event-stream'
    response.stream.write(": starting up stream\n\n")
    Feature.all.each do |feature|
      color = "#000088"
      response.stream.write("data: {m_z:#{feature.m_z},rt:#{feature.rt},id:#{feature.id},color:'#{color}'}\n\n")
    end
  ensure
    response.stream.close
  end

  def show
    @feature = Feature.find(params[:feature])
  end
end
