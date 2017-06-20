#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "aai"
require "trollop"

opts = Trollop.options do
  banner <<-EOS

  AAI

  Options:
  EOS

  # opt(:infile, "Input file", type: :string)
  # opt(:outdir, "Output directory", type: :string, default: ".")
end

Aai.check_files ARGV
Aai.process_input_seqs! ARGV
