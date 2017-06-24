require "abort_if"
require "systemu"
require "parallel"
require "parse_fasta"

require "aai/core_extensions"
require "aai/utils"
require "aai/version"

AbortIf.extend AbortIf
Process.extend Aai::CoreExtensions::Process
Time.extend Aai::CoreExtensions::Time

module Aai
  include Utils

  BLAST_DB_SEPARATOR = "...."
  BLAST_DB_SUFFIX    = "#{BLAST_DB_SEPARATOR}aai"

  PIDENT_CUTOFF = 30
  EVALUE_CUTOFF = 1e-3
  LENGTH_CUTOFF = 70 # actually is 70 percent

  # If a blast job fails, it will retry once. If it fails again, it
  # will be ignored by the rest of the pipeline.
  def blast_permutations! fastas, blast_dbs, cpus=4
    file_permutations = one_way_combinations fastas, blast_dbs, true
    file_permutations = file_permutations.select do |f1, f2|
      genome_from_fname(f1) != genome_from_fname(f2)
    end

    completed_outf_names = []
    failed_jobs = []

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

    args = first_files.length.times.map do |idx|
      [first_files[idx], second_files[idx], outf_names[idx]]
    end

    Time.time_it "Running blast jobs" do
      args.each_with_index do |infiles, idx|
        query = infiles[0]
        db    = infiles[1]
        out   = infiles[2]

        cmd = "diamond blastp --threads #{cpus} --outfmt 6 " +
              "--query #{query} --db #{db} --out #{out} " +
              "--evalue #{EVALUE_CUTOFF}"

        exit_status = Process.run_it cmd

        if exit_status.zero?
          completed_outf_names << out
        else
          failed_jobs << idx
          AbortIf.logger.warn { "Blast job failed. Non-zero exit status " +
                                "(#{exit_status}) " +
                                "when running '#{cmd}'. " +
                                "Will retry at end." }
        end
      end
    end

    if failed_jobs.count > 0
      Time.time_it "Retrying failed blast jobs" do
        # retry failed jobs once
        failed_jobs.each do |idx|
          query = args[idx][0]
          db    = args[idx][1]
          out   = args[idx][2]

          cmd = "diamond blastp --threads #{cpus} --outfmt 6 " +
                "--query #{query} --db #{db} --out #{out} " +
                "--evalue #{EVALUE_CUTOFF}"

          exit_status = Process.run_it cmd

          if exit_status.zero?
            completed_outf_names << out
          else
            AbortIf.logger.error { "Retrying blast job failed. " +
                                   "Non-zero exit status " +
                                   "(#{exit_status}) " +
                                   "when running '#{cmd}'." }
          end
        end
      end
    end

    completed_outf_names
  end

  # Make blast dbs given an array of filenames.
  #
  # @param fnames [Array<String>] an array of filenames
  # @param cpus [Integer] number of cpus to use
  #
  # @return [Array<String>] blast db basenames
  def make_blastdbs! fnames, cpus=4
    suffix = BLAST_DB_SUFFIX
    outfiles = fnames.map { |fname| fname + suffix }

    Time.time_it "Making blast databases" do
      fnames.each do |fname|
        cmd = "diamond makedb --threads #{cpus} --in #{fname} " +
              "--db #{fname}#{BLAST_DB_SUFFIX}"

        Process.run_it! cmd
      end
    end

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
          unless bad_seq? rec.seq
            header =
              annotate_header clean_header(rec.header),
                              File.basename(fname)

            seq_lengths[header] = rec.seq.length

            f.puts ">#{header}\n#{rec.seq}"
          end
        end
      end
    end

    [seq_lengths, clean_fnames]
  end

  def get_best_hits fnames, seq_lengths
    best_hits = {}
    fnames.each do |fname| # blast files
      File.open(fname, "rt").each_line do |line|
        ary = line.chomp.split "\t"

        query  = ary[0]
        target = ary[1]
        pident = ary[2].to_f
        length = ary[3].to_f
        evalue = ary[10].to_f

        query_genome = query.split("____").first
        query_seq    = query.split("____").last

        target_genome = target.split("____").first
        target_seq    = target.split("____").last

        seq_length_key = "#{query_genome}____#{query_seq}"

        AbortIf.abort_unless seq_lengths.has_key?(seq_length_key),
                             "#{seq_length_key} is missing from " +
                             "seq_lengths"

        query_length = seq_lengths[seq_length_key].to_f
        length_percent = length / query_length * 100

        hit_info = {
          query_name: query_seq,
          target_name: target_seq,
          query_genome: query_genome,
          target_genome: target_genome,
          pident: pident,
          length: length_percent,
          evalue: evalue
        }

        # check if it is a best hit candidate
        if pident >= PIDENT_CUTOFF &&
           evalue <= EVALUE_CUTOFF &&
           length_percent >= LENGTH_CUTOFF

          if best_hits.has_key? query_genome
            if best_hits[query_genome].has_key? query_seq
              if best_hits[query_genome][query_seq].
                  has_key?(target_genome)
                # check if we should replace the best hit?
                current_best_hit =
                  best_hits[query_genome][query_seq][target_genome]

                if pident >= current_best_hit[:pident]
                  best_hits[query_genome][query_seq][target_genome] =
                    hit_info
                end
              else
                best_hits[query_genome][query_seq][target_genome] =
                  hit_info
              end
            else
              best_hits[query_genome][query_seq] = {
                target_genome => hit_info
              }
            end
          else
            best_hits[query_genome] = {
              query_seq => {
                target_genome => hit_info
              }
            }
          end
        else
          # pass
        end
      end
    end

    best_hits
  end

  def one_way_aai best_hits
    one_way_best_hits(best_hits).map do |genome_pair, best_hits|
      [genome_pair, best_hits.map { |hit| hit[:pident] }.reduce(:+) /
                    best_hits.length.to_f]
    end.to_h
  end

  def two_way_aai best_hits
    # the pair key is the [g1, g2].sort

    two_way_aai = {}

    one_way_hits = one_way_best_hits best_hits
    genome_pair_keys = one_way_hits.keys.map { |pair| pair.sort }.uniq

    genome_pair_keys.each do |pair_key|
      AbortIf.abort_unless one_way_hits.has_key?(pair_key) &&
                           one_way_hits.has_key?(pair_key.reverse),
                           "Missing keys for #{pair_key}"

      forward_hits = one_way_hits[pair_key]
      reverse_hits = one_way_hits[pair_key.reverse]

      combinations = one_way_combinations forward_hits, reverse_hits

      two_way_hits = combinations.select do |h1, h2|
        two_way_hit? h1, h2
      end

      two_way_hit_info = two_way_hits.map do |h1, h2|
        { genome_pair: [h1[:query_genome],
                        h1[:target_genome]].sort,
          pident: (h1[:pident] + h2[:pident]) / 2.0 }
      end

      two_way_hit_info.each do |hit|
        if two_way_aai.has_key? hit[:genome_pair]
          two_way_aai[hit[:genome_pair]] << hit[:pident]
        else
          two_way_aai[hit[:genome_pair]] = [hit[:pident]]
        end
      end
    end

    two_way_aai.map do |genome_pair, pidents|
      [genome_pair, pidents.reduce(:+) / pidents.length.to_f]
    end.to_h
  end

  # Returns an array (enumerable) of aai strings ready to print
  def aai_strings one_way_aai, two_way_aai
    aai_strings = {}
    keys = (one_way_aai.keys + two_way_aai.keys).
           map { |key| key.sort }.uniq

    keys.each do |key|
      a_to_b_aai = one_way_aai[key] || "NA"
      b_to_a_aai = one_way_aai[key.reverse] || "NA"
      two_way = two_way_aai[key] || "NA"

      aai_strings[key] = [a_to_b_aai,
                          b_to_a_aai,
                          two_way]
    end

    aai_strings.map do |genome_pair, aais|
      [genome_pair.join("----"),
       aais.join("\t")].join "\t"
    end
  end

  private

  # this is to account for the weird IMG error. Some seqs will
  # not have an actual protein, rather it will be "No sequence
  # found"
  def bad_seq? seq
    seq.downcase.include? "nosequencefound"
  end

  def two_way_hit? hit1, hit2
    hit1[:query_name] == hit2[:target_name] &&
      hit1[:query_genome] == hit2[:target_genome]
  end

  def one_way_best_hits best_hits
    one_way = {}

    best_hits.each do |query_genome, orfs|
      orfs.each do |orf, target_genomes|
        target_genomes.each do |target_genome, best_hit|
          genome_pair = [query_genome, target_genome]
          if one_way.has_key? genome_pair
            one_way[genome_pair] << best_hit
          else
            one_way[genome_pair] = [best_hit]
          end
        end
      end
    end

    one_way
  end

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
