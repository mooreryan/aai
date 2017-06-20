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
  end
end
