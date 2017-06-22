require "spec_helper"

RSpec.describe Aai::Utils do
  let(:klass) { Class.extend Aai::Utils }
  let(:exit_error) { SystemExit }

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
      binary = "arsotienarsotine"

      expect(klass.command? binary).to be nil
    end

    it "returns nil if file is on path but not executable" do
      binary = "arstoienarstoien1234123456789"
      `export $PATH:#{binary}`

      expect(klass.command? binary).to be nil
    end

    it "returns the path to program its on path and is executable" do
      binary = "ruby"

      expect(klass.command? binary).to be_truthy
    end
  end
end
