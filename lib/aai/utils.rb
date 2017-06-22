module Aai
  module Utils
    # Raises SystemExit if one of the fnames does not exist.
    def check_files fnames
      fnames.each do |fname|
        AbortIf.abort_unless_file_exists fname
      end
    end

    def two_ary_permutations a1, a2
      permutations = []

      a1.each do |elem1|
        a2.each do |elem2|
          permutations << [elem1, elem2] << [elem2, elem1]
        end
      end

      permutations
    end

    def one_way_combinations a1, a2, no_duplicates=true
      permutations = []

      a1.each do |elem1|
        a2.each do |elem2|
          if !no_duplicates || (no_duplicates && elem1 != elem2)
            permutations << [elem1, elem2]
          end
        end
      end

      permutations
    end

    # from https://stackoverflow.com/questions/2108727/ \
    # which-in-ruby-checking-if-program-exists-in-path-from-ruby
    def command? cmd
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      return nil
    end

    def check_command cmd
      path = command? cmd

      AbortIf.abort_unless path,
                           "Missing #{cmd} command. " +
                           "Is it executable and on your path?"

      path
    end
  end
end
