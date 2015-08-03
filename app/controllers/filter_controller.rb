class FilterController < ApplicationController
  include FilterHelper
  def edit
    # for histograms
    @criteria = FilteringCriteria.new(session)
    if not params['minimal'].nil?
      print 'saving filtering'
      #first save absolute filtering criteria
      ['score','fragmentation_score','isotope_similarity','mass_error','adducts'].each do |crit|
        @criteria.minimal[crit] = params['minimal'][crit].to_f
      end
      @criteria.relative.sort! {|a,b| params['relative'][a] <=> params[:relative][b]}
      @criteria.oxichain! params['oxichain']
      @criteria.save session
    end
  end

  def list_oxi
    @criteria = FilteringCriteria.new session
    #@samples = Sample.to_hash
  end

  def get_list_oxi
    crit = FilteringCriteria.new session
    # get all oxichains
    oxichain_ids = {}
    oxichains = Feature.all.group(:oxichain).pluck(:oxichain)
    oxichains.each do |oxichain|
      next if oxichain.nil? #no oxichain => continue
      # get all parental lipids for an oxichain
      features = []
      ActiveRecord::Base.connection.execute("SELECT id FROM features WHERE oxichain=#{oxichain.to_i}").each do |feature|
        features << feature[0]
      end
      features = features.join(",")
      identifications = ActiveRecord::Base.connection.execute("SELECT parent FROM lipids,identifications WHERE feature_id IN (#{features}) AND lipids.id=lipid_id")
      parents = {}
      # get parents with most hits
      identifications.each do |parent|
        parents[parent[0]] ||= 0
        parents[parent[0]] += 1
      end
      best_parents = []
      n = 0
      parents.each do |parent, n_ids|
        if n_ids > n
          best_parents = [parent]
          n = n_ids
        elsif n_ids == n
          best_parents.push parent
        end
      end
      #ignore an oxichain with less than two parental identifications
      next if n<2
      # find best parent
      identifications = []
      Identification.find_by_sql("SELECT * from identifications WHERE feature_id IN (#{features}) AND lipid_id IN (SELECT id FROM lipids WHERE parent IN ('#{best_parents.join("','")}'))").each do |id|
        identifications << id
        crit.relative.reverse_each do |criterium|
          case criterium
            when 'score'
              identifications.sort! {|a,b| if a.score > b.score
                                             1  #b follows a
                                           elsif b.score > a.score
                                             -1 #a follows b
                                           else
                                             0 # a and b are equivalent
                                           end
              }
            when 'fragmentation_score'
              identifications.sort! {|a,b| if a.fragmentation_score > b.fragmentation_score
                                             1  #b follows a
                                           elsif b.fragmentation_score > a.fragmentation_score
                                             -1 #a follows b
                                           else
                                             0 # a and b are equivalent
                                           end
              }
            when 'isotope_similarity'
              identifications.sort! {|a,b| if a.isotope_similarity > b.isotope_similarity
                                             1  #b follows a
                                           elsif b.isotope_similarity > a.isotope_similarity
                                             -1 #a follows b
                                           else
                                             0 # a and b are equivalent
                                           end
              }
            when 'mass_error'
              identifications.sort! {|a,b| if a.mass_error > b.mass_error
                                             1  #b follows a
                                           elsif b.mass_error > a.mass_error
                                             -1 #a follows b
                                           else
                                             0 # a and b are equivalent
                                           end
              }
            when 'adducts'
              identifications.sort! {|a,b| if a.adducts > b.adducts
                                             1  #b follows a
                                           elsif b.adducts > a.adducts
                                             -1 #a follows b
                                           else
                                             0 # a and b are equivalent
                                           end
              }
            else
              raise StandardError, 'Tried to sort by parameter %s, but this parameter does not exist.'%criterium
          end
        end
      end
      best_id = identifications[0]
      oxichain_ids[oxichain] = best_id
    end
    oxichains = {}
    oxichains['samples'] = Sample.order(:group_id).find_all
    oxichains['groups'] = Group.all.find_all
    oxichain_ids.each do |oxichain, id|
      oxichains[oxichain] = {id: id}
      oxichains[oxichain]['lipid'] = Lipid.find(id.lipid_id)
      oxichains[oxichain]
      Feature.where(oxichain: oxichain).order(m_z: :asc).includes(:quantifications).find_each do |feature|
        oxichains[oxichain][feature.id_string] = feature.quants
      end
    end

    render :json => oxichains
  end

  def list
    @criteria = FilteringCriteria.new session
    @samples = Sample.to_hash
  end

  def get_list
    @criteria = FilteringCriteria.new session
    @results = filteredIdentifications(@criteria)
    #@results = [Identification.find(383093),Identification.find(384995),Identification.find(382925)]
    @criteria.save(session)
    @oxichains = {}
    features = {}
    @results.each do |id|
      @oxichains[id.feature.oxichain] = id.lipid.parent
      features[id.feature.id] = true
    end
    unless @criteria.oxichain==false
      @oxifeatures = Feature.includes(:identifications, :quantifications).where(oxichain: @oxichains.keys).where.not(id: features.keys).where ('oxichain IS NOT NULL')
    else
      @oxifeatures = []
    end

    render layout:false
  end

  def statistics
    score_list = []
    frag_score_list = []
    iss_list = []
    adducts_list = []
    mass_error_list = []
    Identification.find_each do |ident|
      score_list << ident.score
      frag_score_list << ident.fragmentation_score
      iss_list << ident.isotope_similarity
      adducts_list << ident.adducts
      mass_error_list << ident.mass_error
    end

    score_dist = score_list.distribution
    frag_score_dist = frag_score_list.distribution
    iss_dist = iss_list.distribution
    adducts_dist = adducts_list.distribution("integer")
    mass_error_dist = mass_error_list.distribution()

    # sort
    @score_dist = Hash[*score_dist.sort_by{|key, value| key.first.to_f}.flatten]
    @frag_score_dist = Hash[*frag_score_dist.sort_by{|key, value| key.first.to_f}.flatten]
    @iss_dist = Hash[*iss_dist.sort_by{|key, value| key.first.to_f}.flatten]
    @adducts_size_dist = Hash[*adducts_dist.sort_by{|key, value| key.first.to_f}.flatten]
    @mass_error_dist = Hash[*mass_error_dist.sort_by{|key, value| key.first.to_f}.flatten]

    #session['score_dist'] = Hash[*score_dist.sort_by{|key, value| key.first.to_f}.flatten]
    #session['frag_score_dist'] = Hash[*frag_score_dist.sort_by{|key, value| key.first.to_f}.flatten]
    #session['iss_dist'] = Hash[*iss_dist.sort_by{|key, value| key.first.to_f}.flatten]
    #session['adducts_size_dist'] = Hash[*adducts_dist.sort_by{|key, value| key.first.to_f}.flatten]
    #session['mass_error_dist'] = Hash[*mass_error_dist.sort_by{|key, value| key.first.to_f}.flatten]

    @score_list = [score_list.min, score_list.max, score_list.ave, score_list.sd]
    @frag_score_list = [frag_score_list.min, frag_score_list.max, frag_score_list.ave, frag_score_list.sd]
    @iss_list = [iss_list.min, iss_list.max, iss_list.ave, iss_list.sd]
    @adducts_list = [adducts_list.min, adducts_list.max, adducts_list.ave, adducts_list.sd]
    @mass_error_list = [mass_error_list.min, mass_error_list.max, mass_error_list.ave, mass_error_list.sd]

    render layout:false
  end
end
