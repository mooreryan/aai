require "spec_helper"

RSpec.describe Aai::Utils do
  let(:klass) { Class.extend Aai::Utils }
  let(:exit_error) { SystemExit }

  describe "#clean_str" do
    it "changes all non alphanumeric characters to an _" do
      str = "  a#%@p$#%@p.,/l]['    e   %   "

      expect(klass.clean_str str).to eq "a_p_p_l_e_"
    end
  end

  describe "#check_files" do
    it "raises if one of the files doesn't exist" do
      fnames = [SpecHelper::G1_FNAME, "apple.txt"]

      expect { klass.check_files fnames }.to raise_error exit_error
    end

    it "doesn't raise if files do exist" do
      fnames = SpecHelper::IN_FNAMES

      expect { klass.check_files fnames }.not_to raise_error
    end
  end

  describe "#two_ary_permutations" do
    it "returns all permutations of elements in ary 1 with ary 2" do
      a1 = [1, 2]
      a2 = [:a, :b, :c]
      permutations = [
        [1, :a], [:a, 1],
        [1, :b], [:b, 1],
        [1, :c], [:c, 1],

        [2, :a], [:a, 2],
        [2, :b], [:b, 2],
        [2, :c], [:c, 2],
      ]

      expect(klass.two_ary_permutations a1, a2).
        to eq permutations
    end
  end

  describe "#one_way_combinations" do
    it "returns a1 to a2 combinations for two arrays" do
      a1 = [1, 2]
      a2 = [:a, :b, :c]

      combinations = [
        [1, :a],
        [1, :b],
        [1, :c],

        [2, :a],
        [2, :b],
        [2, :c],
      ]

      expect(klass.one_way_combinations a1, a2).
        to eq combinations
    end

    context "with no_duplicates flag to truee" do
      it "doesn't include combinations with duplicates" do
        a1 = [1, 2, 3]
        a2 = [1, 2, 3]

        combinations = [
          [1, 2],
          [1, 3],
          [2, 1],
          [2, 3],
          [3, 1],
          [3, 2],
        ]

        expect(klass.one_way_combinations a1, a2, true).
          to eq combinations
      end
    end
  end

  describe "#command?" do
    it "returns nil if file is not on path" do
      cmd = "arsotienarsotine"

      expect(klass.command? cmd).to be nil
    end

    it "returns nil if file is on path but not executable" do
      cmd = "arstoienarstoien1234123456789"
      `export PATH=$PATH:#{cmd}`

      expect(klass.command? cmd).to be nil
    end

    it "returns the path to program its on path and is executable" do
      cmd = "ruby"

      expect(klass.command? cmd).to be_truthy
    end
  end

  describe "#check_command" do
    it "raises SystemExit when command? is falsey" do
      cmd = "arsoteinoieansrtoiaernstoieanrstoan"

      expect { klass.check_command cmd }.to raise_error SystemExit
    end

    it "returns path to program if cmd is on path and is executable" do
      cmd = "ruby"

      expect(klass.check_command cmd).to be_truthy
    end
  end
end
