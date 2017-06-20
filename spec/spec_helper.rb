require "coveralls"
Coveralls.wear!

require "bundler/setup"
require "aai"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module SpecHelper
  TEST_DIR = File.join File.dirname(__FILE__), "test_files"
  G1_FNAME = File.join TEST_DIR, "g1.fa"
  G2_FNAME = File.join TEST_DIR, "g2.fa"
  G3_FNAME = File.join TEST_DIR, "g3.fa"
  IN_FNAMES = [G1_FNAME, G2_FNAME, G3_FNAME]
  CLEAN_FNAMES = IN_FNAMES.map { |fname| fname + "_aai_clean" }

  # BLAST_DBS = CLEAN_FNAMES.map { |fname| ["#{fname}....aai.phr",
  #                                         "#{fname}....aai.pin",
  #                                         "#{fname}....aai.psq"] }.flatten

  BLAST_DBS = Dir.glob(File.join(TEST_DIR, "*....aai.p*"))

  BLAST_DB_BASENAMES = CLEAN_FNAMES.map { |fname| fname + "....aai" }
  BTAB_FILES = %w[g1 g2 g3].permutation(2).map do |g1, g2|
    File.join TEST_DIR, "#{g1}____#{g2}.aai_blastp"
  end

  SELF_BTABS = ["g1____g1.aai_blastp",
                "g2____g2.aai_blastp",
                "g3____g3.aai_blastp"].map do |fname|
    File.join TEST_DIR, fname
  end
end
