#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "aai"
require "trollop"

Aai.extend Aai
Aai.extend Aai::Utils


opts = Trollop.options do
  banner <<-EOS

  AAI

  Options:
  EOS

  opt(:infiles, "Input files", type: :strings)
  # opt(:outdir, "Output directory", type: :string, default: ".")
end

p opts[:infiles]

Aai.check_files opts[:infiles]

seq_lengths, clean_fnames = Aai.process_input_seqs! opts[:infiles]

blast_db_basenames = Aai.make_blastdbs! clean_fnames

btabs = Aai.blast_permutations! clean_fnames, blast_db_basenames

best_hits = Aai.get_best_hits btabs

one_way = Aai.one_way_aai best_hits

two_way = Aai.two_way_aai best_hits

File.open("teehee.txt", "w") do |f|
  Aai.aai_strings(one_way, two_way).each do |str|
    f.puts str
  end
end
