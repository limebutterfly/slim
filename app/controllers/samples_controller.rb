class SamplesController < ApplicationController
  def group
    @samples = Sample.all.includes(:group).order(:group_id, :id_string).find_all
  end

  def group_save
    json = params[:_json]
    json.each do |group|
      if group['id'] == "0"
        Sample.where(id: group['items']).update_all(group_id: nil)
        next
      elsif group['id'][0,3] == 'new'
        g = Group.create name: group['name']
      else
        g = Group.find(group['id'].to_i)
        if g.nil?
          return 0
        end
        g.name = group['name']
        g.save
      end
      Sample.where(id: group['items']).update_all(group_id: g.id)
    end
    render :text => '1'
  end
end
