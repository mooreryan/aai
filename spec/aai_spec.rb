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

RSpec.describe Aai do
  it "has a version number" do
    expect(Aai::VERSION).not_to be nil
  end

  let(:klass) { Class.extend Aai }
  let(:in_fastas) { SpecHelper::IN_FNAMES }
  let(:blast_dbs) { in_fastas.map { |fname| fname + "....aai" } }
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
    delete_all SpecHelper::BLAST_DBS
    delete_all SpecHelper::CLEAN_FNAMES
    delete_all SpecHelper::BTAB_FILES
  end

  after :each do
    delete_all SpecHelper::BLAST_DBS
    delete_all SpecHelper::CLEAN_FNAMES
    delete_all SpecHelper::BTAB_FILES
  end

  describe "#blast_permutations!" do
    it "blasts all permutations of infiles" do
      klass.make_blastdbs! in_fastas

      klass.blast_permutations! in_fastas, blast_dbs

      expect(all_exist? SpecHelper::BTAB_FILES).to be true
    end

    it "doesn't do self blasts" do
      klass.make_blastdbs! in_fastas

      klass.blast_permutations! in_fastas, blast_dbs

      expect(none_exist? SpecHelper::SELF_BTABS).to be true
    end
  end

  describe "#make_blastdbs!" do
    it "makes a blast db for each infile" do
      klass.make_blastdbs! in_fastas

      expect(all_exist? SpecHelper::BLAST_DBS).to be true
    end

    it "returns the blast db basenames" do
      expect(klass.make_blastdbs! in_fastas).
        to eq blast_dbs
    end
  end

  describe "#process_input_seqs!" do
    it "returns an HT of seq lengths, and the clean file names" do
      expect(klass.process_input_seqs! in_fastas).
        to eq [seq_lengths, SpecHelper::CLEAN_FNAMES]
    end

    it "writes new files with clean header names" do
      klass.process_input_seqs! in_fastas

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
