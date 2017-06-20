require "abort_if"
require "systemu"
require "parse_fasta"

require "aai/core_extensions"
require "aai/utils"
require "aai/version"

AbortIf.extend AbortIf
Process.extend Aai::CoreExtensions::Process

module Aai
  include Utils

  BLAST_DB_SEPARATOR = "...."
  BLAST_DB_SUFFIX    = "#{BLAST_DB_SEPARATOR}aai"

  def blast_permutations! fastas, blast_dbs
    file_permutations = one_way_combinations fastas, blast_dbs, true
    file_permutations = file_permutations.select do |f1, f2|
      genome_from_fname(f1) != genome_from_fname(f2)
    end

    first_files = file_permutations.map(&:first)
    second_files = file_permutations.map(&:last)

    first_genomes = first_files.map do |fname|
      ary = fname.split(".")
      ary.take(ary.length - 1).join
    end

    second_genomes = second_files.map do |fname|
      ary = fname.split(BLAST_DB_SEPARATOR).take(1)
      AbortIf.abort_unless ary.length == 1,
                   "Bad file name for #{fname}"

      ary = ary.first.split(".")

      File.basename ary.take(ary.length - 1).join
    end

    outf_names = first_genomes.zip(second_genomes).map do |f1, f2|
      "#{f1}____#{f2}.aai_blastp"
    end

    title = "Running blast jobs"
    cmd = "parallel --link blastp -outfmt 6 " +
          "-query {1} -db {2} " +
          "-out {3} -evalue 1e-3 " +
          "::: #{first_files.join " "} ::: " +
          "#{second_files.join " "} ::: " +
          "#{outf_names.join " "}"

    Process.run_and_time_it! title, cmd
  end

  # Make blast dbs given an array of filenames.
  #
  # @param fnames [Array<String>] an array of filenames
  #
  # @return [Array<String>] blast db basenames
  def make_blastdbs! fnames
    suffix = BLAST_DB_SUFFIX
    outfiles = fnames.map { |fname| fname + suffix }

    title = "Making blast databases"
    cmd = "parallel makeblastdb -in {} " +
          "-out {}#{BLAST_DB_SUFFIX} -dbtype prot " +
          "::: #{fnames.join " "}"

    Process.run_and_time_it! title, cmd

    outfiles
  end

  # Returns a hash table with sequence lengths and writes new fasta
  # files with clean headers for blast.
  #
  # The sequences are annotated with the genome that they came from.
  #
  # @param fnames [Array<String>] an array of fasta file names
  def process_input_seqs! fnames
    seq_lengths = {}
    clean_fnames = []

    fnames.each do |fname|
      clean_fname = fname + "_aai_clean"
      clean_fnames << clean_fname
      File.open(clean_fname, "w") do |f|
        Object::ParseFasta::SeqFile.open(fname).each_record do |rec|
          header =
            annotate_header clean_header(rec.header),
                            File.basename(fname)

          seq_lengths[header] = rec.seq.length

          f.puts ">#{header}\n#{rec.seq}"
        end
      end
    end

    [seq_lengths, clean_fnames]
  end

  private

  def genome_from_fname fname
    fname_no_aai = fname.split(BLAST_DB_SEPARATOR).first
    ext = fname_no_aai.split(".").last
    genome = File.basename fname_no_aai, ".#{ext}"

    genome
  end

  def clean_header header
    header.gsub(/ +/, "_")
  end

  # Adds the file name to the header minus the directory and the
  # final extension.
  #
  # @note If the file is blah.fa.gz or something like that, then the
  #   genome name will be blah.fa, and not just blah.
  def annotate_header header, fname
    genome = genome_from_fname fname

    "#{genome}____#{header}"
  end
end
