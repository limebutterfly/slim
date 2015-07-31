class FeaturesController < ApplicationController
  include ActionController::Live
  include FeaturesHelper
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
    Feature.all.order(m_z: :asc).find_each do |feature|
      color = "#000088"
      response.stream.write("data: [{m_z:#{feature.m_z},rt:#{feature.rt},id:#{feature.id},color:'#{feature.oxichain? ? '#880000': color}', oxichain:#{feature.oxichain.nil? ? 'null' : feature.oxichain}}]\n\n")
    end
  ensure
    response.stream.close
  end

  def show
    @feature = Feature.find(params[:feature])
  end
  def oxichain

  end

  def oxichain_export
    response.headers['Content-Type'] = 'text/csv'
    out = "feature_id;base_id;oxichain;mz;rt;drt;dmz\n"
    oxichain = {}
    Feature.where.not(oxichain: nil).order(:oxichain, :m_z).each do |feature|
      oxichain[feature.oxichain] ||= []
      oxichain[feature.oxichain] << feature
    end
    oxichain.each do |key, features|
      first = nil
      features.each do |feature|
        if first.nil?
          first=feature
          next
        end
        out << "%i;%i;%i;%.4f;%.4f;%.4f;%.6f\n"%[feature.id,first.id,key,first.m_z,first.rt,feature.rt-first.rt,feature.m_z-first.m_z-15.994915]
        first=feature
      end
    end
    render text: out
  end


  def oxichain_find
    response.headers['Content-Type'] = 'text/event-stream'
    def log(data)
      response.stream.write("data: #{data}\n\n")
    end
    log('deleting old oxichain information')
    Feature.all.update_all(oxichain:nil)
    #initialize helper integers
    total_features = Feature.count
    processed_features = 0
    found_oxichains = 1
    features_in_oxichain = 0
    log("    ....   #{total_features} features to process ....")
    Feature.order(m_z: :asc).each do |feature|
      processed_features += 1
      next unless feature.oxichain.nil? #skip feature if it already has been assigned to an oxichain
      oxichain_members = []
      #must only search upwards since features are ordered by mz.
      current_oxidized_feature = search_oxidated feature
      until current_oxidized_feature.nil?
        oxichain_members << current_oxidized_feature
        current_oxidized_feature = search_oxidated current_oxidized_feature
      end
      if oxichain_members.count > 0
        oxichain_members.unshift feature
        member_string = []
        oxichain_members.each do |oxichain_member|
          oxichain_member.update_column(:oxichain, found_oxichains)
          member_string << "<a href='/features/show/#{oxichain_member.id}'>#{oxichain_member.id_string}</a>"
        end
        log(" ... found oxichain #{found_oxichains}: members are: #{member_string.join ', '}.")
        found_oxichains += 1
        features_in_oxichain << oxichain_members.length
      end
      if processed_features%200==0
        log("(#{"%.0f"%(100.0*processed_features/total_features)}%)    ....   done with #{processed_features} of #{total_features} features  ....")
      end
    end
    log("100%! Terminated oxichain search - found total #{found_oxichains-1} of #{features_in_oxichain} features in an oxichain (#{"%.1f"%(100.0*features_in_oxichain/total_features)}%)")
  rescue
    response.stream.write("data: ABORTED! An error occured: #{$!}")
    raise
  ensure
    response.stream.close
  end
end
