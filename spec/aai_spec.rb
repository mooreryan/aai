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

  # Genomes have many ORFs
  # ORFs have zero or one best hits from each genome
  let(:best_hits) do
    {
      "g1" => { # genome 1
        "o1" => { # ORF 1 from genome 1
          "g2" => { # Best hit of ORF from genome 1 in genome 2
            query_name: "o1",
            target_name: "o1", # description of best hit
            query_genome: "g1",
            target_genome: "g2",
            pident: 80,
            length: 100,
            evalue: 1e-3
          }
        },
        "o2" => { # ORF 2 from genome 1
          "g2" => { # ORF 2 best hit in genome 2
            query_name: "o2",
            target_name: "o2",
            query_genome: "g1",
            target_genome: "g2",
            pident: 100,
            length: 100,
            evalue: 1e-3
          }
        }
      },
      "g2" => { # genome 2
        "o1" => { # orf 1 in genome 2
          "g1" => { # orf 1 in genome 2 best hit in genome 1
            query_name: "o1",
            target_name: "o3", # hit description
            query_genome: "g2",
            target_genome: "g1",
            pident: 100,
            length: 100,
            evalue: 1e-3,
          }
        },
        "o2" => { # orf 2 in genome 2
          "g1" => { # orf 2 in genome 2 its best hit in genome 1
            query_name: "o2",
            target_name: "o2", # description of hit
            query_genome: "g2",
            target_genome: "g1",
            pident: 90,
            length: 100,
            evalue: 1e-3,
          }
        }
      }
    }
  end

  let(:one_way_aai) do
    { %w[g1 g2] => 90,
      %w[g2 g1] => 95, }
  end

  let(:two_way_aai) do
    { %w[g1 g2] => 95 }
  end

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
      seq_lengths, clean_fnames = klass.process_input_seqs! SpecHelper::IN_FNAMES

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

    it "returns the names of the btab files" do
      seq_lengths, clean_fnames = klass.process_input_seqs! SpecHelper::IN_FNAMES

      blast_db_basenames = klass.make_blastdbs! clean_fnames

      btabs = klass.blast_permutations! clean_fnames,
                                        blast_db_basenames

      expect(btabs).to eq SpecHelper::BTAB_FILES
    end
  end

  describe "#make_blastdbs!" do
    it "makes a blast db for each infile" do
      blast_db_basenames = klass.make_blastdbs! SpecHelper::IN_FNAMES

      outfiles = blast_db_basenames.map do |fname|
        "#{fname}.dmnd"
      end

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

  describe "#get_best_hits" do
    it "returns the best hits for each genome" do
      g1_g2_btab = File.join SpecHelper::TEST_DIR, "g1.g2.btab"
      g2_g1_btab = File.join SpecHelper::TEST_DIR, "g2.g1.btab"

      these_seq_lengths = { "g1____o1" => 65,
                            "g1____o2" => 65,
                            "g1____o3" => 63,

                            "g2____o1" => 65,
                            "g2____o2" => 65,
                            "g2____o3" => 63 }

      calc_best_hits = klass.get_best_hits [g1_g2_btab, g2_g1_btab],
                                           these_seq_lengths

      expect(calc_best_hits).to eq best_hits
    end
  end

  describe "#one_way_aai" do
    it "calculates one way aai" do
      expect(klass.one_way_aai best_hits).to eq one_way_aai
    end
  end

  describe "#two_way_aai" do
    it "calculates two way aai" do
      expect(klass.two_way_aai best_hits).to eq two_way_aai
    end
  end

  describe "#aai_strings" do
    it "prints the aai info" do
      aai_string = [["g1----g2", 90, 95, 95].join("\t")]

      expect(klass.aai_strings one_way_aai, two_way_aai).
        to eq aai_string
    end
  end
end
