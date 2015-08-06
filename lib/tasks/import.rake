namespace :import do

  desc "Import Identifications file"
  task id: :environment do
    t0 = Time.now
    include ImportIdentificationsHelper
    file = ENV['file']
    file ||= 'sample_data/COMPOUND_IDs.csv'
    puts '    importing identifications file %s'%file
    Identification.delete_all
    puts '    deleted old identification data'
    puts importIdentifications(file)
    puts "    completed task in  #{"%.2f" % (Time.now - t0)}s"

  end

  desc "Import Quantifications file"
  task quant: :environment do
    t0 = Time.now

    include ImportQuantificationsHelper
    require 'csv'
    file = ENV['file']
    file ||= 'sample_data/COMPOUND_quantities.csv'
    puts '    importing quantification file %s'%file
    puts '    ... deleting old quantifications, samples and features, this may take a while'
    Quantification.delete_all
    Sample.delete_all
    Feature.delete_all
    puts '    deleted old quantification data'
    puts importQuantifications(file)
    puts "    completed task in  #{"%.2f" % (Time.now - t0)}s"
  end


  desc "Import SDF file"
  task sdf: :environment do
    t0 = Time.now
    include ImportLipidsHelper
    file = ENV['file']
    file ||= 'sample_data/pc_oxidized.sdf'
    Lipid.delete_all
    puts '    deleted all alreday imported lipids'
    puts importSDF(file)
    puts "    completed task in  #{"%.2f" % (Time.now - t0)}s"
  end

  desc "Import experiment (specify id=filename and quant=filename)"
  task experiment: :environment do
    t0 = Time.now
    include ImportQuantificationsHelper
    require 'csv'
    file = ENV['quant']
    file ||= 'sample_data/COMPOUND_quantities_short.csv'
    puts "#{"%.2f" % (Time.now - t0)}s    importing quantification file #{file}"
    puts '    ... deleting old data ...'
    Quantification.delete_all
    Sample.delete_all
    Feature.delete_all
    Group.delete_all
    puts "#{"%.2f" % (Time.now - t0)}s    deleted old quantification data"
    puts importQuantifications(file)
    puts "#{"%.2f" % (Time.now - t0)}s    --- COMPLETED quantification import, now starting identifications import"
    include ImportIdentificationsHelper
    file = ENV['id']
    file ||= 'sample_data/COMPOUND_IDs_short.csv'
    puts '    importing identifications file %s'%file
    Identification.delete_all
    puts "#{"%.2f" % (Time.now - t0)}s    deleted old identification data"
    puts importIdentifications(file)
    #puts "#{"%.2f" % (Time.now - t0)}s    now deleting all features and quantifications without identification, this may take a while..."
    #ActiveRecord::Base.connection.execute('DELETE FROM features WHERE id NOT IN (SELECT distinct(feature_id) FROM identifications)')
    #ActiveRecord::Base.connection.execute('DELETE FROM quantifications WHERE feature_id NOT IN (SELECT id FROM features)')
    puts "    completed task in  #{"%.2f" % (Time.now - t0)}s"
  end



end
