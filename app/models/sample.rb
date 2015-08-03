class Sample < ActiveRecord::Base
   has_many :quantifications
   belongs_to :group

  def self.to_hash
    return Hash[*self.all.map{|sample| [sample.id, sample.short]}.flatten(1)]
  end
end
