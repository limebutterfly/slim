json.ids do
  json.array!(@results) do |identification|
    json.id identification.id
    json.is_oxifeature false
    json.identification do
      json.extract! identification, :score, :fragmentation_score, :isotope_similarity, :mass_error, :adducts
    end
    json.lipid do
      json.extract! identification.lipid, :id, :common_name, :category_, :main_class, :sub_class, :oxidations, :lm_id
    end
    json.feature do
      json.extract! identification.feature, :id, :id_string, :m_z, :rt, :oxichain
    end
    json.n_ids Identification.where(feature: identification.feature).count
    json.values do
      a = []
      identification.feature.quants.each do |id, value|
        a << value
      end
      json.array! a.flatten
    end
    json.lipid_url do
      json.url lipid_url identification.lipid
    end
    json.feature_url do
      json.url feature_url identification.feature
    end
  end
end
json.oxifeatures do
  json.array! (@oxifeatures) do |feature|
    json.feature do
      json.extract! feature, :id, :id_string, :m_z, :rt, :oxichain
    end
    id = bestIdentificationFor feature, @criteria, @oxichains
    unless id.nil?
      json.identification do
        json.extract! id, :score, :fragmentation_score, :isotope_similarity, :mass_error, :adducts
      end
      json.lipid do
        json.extract! id.lipid, :id, :common_name, :category_, :main_class, :sub_class, :oxidations, :lm_id
      end
      json.lipid_url do
        json.url lipid_url id.lipid
      end
      json.has_id true
    else
      json.has_id false
    end

    json.is_oxifeature true
    json.n_ids Identification.where(feature: feature).count
    json.values do
      a = []
      feature.quants.each do |id, value|
        a << value
      end
      json.array! a.flatten
    end
    json.feature_url do
      json.url feature_url feature
    end
  end
end