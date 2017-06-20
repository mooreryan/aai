require "spec_helper"

def delete_all fnames
  fnames.each { |fname| File.delete(fname) if File.exists?(fname) }
end

def all_exist? fnames
  fnames.all? { |fname| File.exists? fname }
end

def none_exist? fnames
  fnames.none? { |fname| File.exists? fname }
end

def ls_test_dir
  STDERR.puts `ls #{SpecHelper::TEST_DIR}`
end

RSpec.describe Aai do
  it "has a version number" do
    expect(Aai::VERSION).not_to be nil
  end

  let(:klass) { Class.extend Aai }
  let(:seq_lengths) {
    { "g1____g1_o1" => 65,
      "g1____g1_o2" => 65,
      "g1____g1_o3" => 63,
      "g2____g2_o1" => 65,
      "g2____g2_o2" => 65,
      "g2____g2_o3" => 63,
      "g3____g3_o1" => 65,
      "g3____g3_o2" => 65,
      "g3____g3_o3" => 65,}
  }

  before :each do
    delete_all Dir.glob(File.join(SpecHelper::TEST_DIR, "*....aai.p*"))
    delete_all SpecHelper::CLEAN_FNAMES
    delete_all SpecHelper::BTAB_FILES
  end

  after :each do
    delete_all Dir.glob(File.join(SpecHelper::TEST_DIR, "*....aai.p*"))
    delete_all SpecHelper::BLAST_DBS
    delete_all SpecHelper::CLEAN_FNAMES
    delete_all SpecHelper::BTAB_FILES
  end

  describe "#blast_permutations!" do
    it "blasts all permutations of infiles" do
      seq_lenghts, clean_fnames = klass.process_input_seqs! SpecHelper::IN_FNAMES

      blast_db_basenames = klass.make_blastdbs! clean_fnames

      klass.blast_permutations! clean_fnames,
                                blast_db_basenames

      expect(all_exist? SpecHelper::BTAB_FILES).to be true
    end

    it "doesn't do self blasts" do
      seq_lenghts, clean_fnames = klass.process_input_seqs! SpecHelper::IN_FNAMES

      blast_db_basenames = klass.make_blastdbs! clean_fnames

      # puts `ls #{SpecHelper::TEST_DIR}`

      klass.blast_permutations! clean_fnames,
                                blast_db_basenames

      expect(none_exist? SpecHelper::SELF_BTABS).to be true
    end
  end

  describe "#make_blastdbs!" do
    it "makes a blast db for each infile" do
      blast_db_basenames = klass.make_blastdbs! SpecHelper::IN_FNAMES

      outfiles = blast_db_basenames.map do |fname|
        ["#{fname}.phr",
         "#{fname}.pin",
         "#{fname}.psq"]
      end.flatten

      expect(all_exist? outfiles).to be true
    end

    it "returns the blast db basenames" do
      expect(klass.make_blastdbs! SpecHelper::IN_FNAMES).
        to eq SpecHelper::IN_FNAMES.map { |fname| fname + "....aai" }
    end
  end

  describe "#process_input_seqs!" do
    it "returns an HT of seq lengths, and the clean file names" do
      expect(klass.process_input_seqs! SpecHelper::IN_FNAMES).
        to eq [seq_lengths, SpecHelper::CLEAN_FNAMES]
    end

    it "writes new files with clean header names" do
      klass.process_input_seqs! SpecHelper::IN_FNAMES

      headers = []
      SpecHelper::CLEAN_FNAMES.each do |fname|
        ParseFasta::SeqFile.open(fname).each_record do |rec|
          headers << rec.header
        end
      end

      expect(headers).to eq seq_lengths.keys
    end
  end
end
