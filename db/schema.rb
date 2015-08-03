# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150731074846) do

  create_table "features", force: true do |t|
    t.decimal  "rt",         precision: 12, scale: 9
    t.decimal  "m_z",        precision: 15, scale: 10
    t.decimal  "mass",       precision: 15, scale: 10
    t.integer  "charge"
    t.string   "id_string"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "oxichain"
  end

  add_index "features", ["id_string"], name: "index_features_on_id_string", using: :btree

  create_table "groups", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identifications", force: true do |t|
    t.integer  "feature_id"
    t.integer  "lipid_id"
    t.float    "fragmentation_score", limit: 24
    t.float    "score",               limit: 24
    t.float    "isotope_similarity",  limit: 24
    t.integer  "adducts"
    t.integer  "priority"
    t.float    "mass_error",          limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lipids", force: true do |t|
    t.string   "lm_id"
    t.string   "pubchem_substane_url"
    t.string   "lipid_maps_cmpd_url"
    t.string   "common_name"
    t.string   "systematic_name",      limit: 512
    t.string   "synonyms",             limit: 1024
    t.string   "category_"
    t.string   "main_class"
    t.string   "sub_class"
    t.float    "exact_mass",           limit: 24
    t.string   "formula"
    t.integer  "pubchem_sid",          limit: 8
    t.string   "pubchem_cid"
    t.string   "kegg_id"
    t.string   "chebi_id"
    t.string   "inchi_key"
    t.string   "status"
    t.text     "molfile"
    t.integer  "oxidations"
    t.integer  "oxvariant"
    t.string   "parent"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "oxichain"
  end

  add_index "lipids", ["common_name"], name: "index_lipids_on_common_name", using: :btree
  add_index "lipids", ["lm_id"], name: "index_lipids_on_lm_id", using: :btree
  add_index "lipids", ["parent"], name: "index_lipids_on_parent", using: :btree
  add_index "lipids", ["pubchem_sid"], name: "index_lipids_on_pubchem_sid", using: :btree

  create_table "quantifications", force: true do |t|
    t.integer  "feature_id"
    t.integer  "sample_id"
    t.float    "norm",       limit: 24
    t.float    "raw",        limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "samples", force: true do |t|
    t.text     "id_string",  limit: 2147483647
    t.string   "short"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
  end

  add_index "samples", ["group_id"], name: "index_samples_on_group_id", using: :btree

end
