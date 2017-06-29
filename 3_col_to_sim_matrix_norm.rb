dists = {}
all_things = []
max = 0 # assumes all positive
File.open(ARGV.first).each_line.with_index do |line, idx|
  unless idx.zero?
    thing1, thing2, dist, *rest = line.chomp.split "\t"

    unless dist == "NA"

      dist = dist.to_f

      max = dist if dist > max

      all_things << thing1 << thing2

      if dists.has_key? thing1
        dists[thing1][thing2] = dist
      else
        dists[thing1] = { thing2 => dist }
      end

      if dists.has_key? thing2
        dists[thing2][thing1] = dist
      else
        dists[thing2] = { thing1 => dist }
      end
    end
  end
end

if max.zero?
  abort "ERROR max is still 0"
end

all_sorted = all_things.uniq.sort

puts all_sorted.join "\t"
all_sorted.each_with_index do |row, ridx|
  row_dists = []
  all_sorted.each_with_index do |col, cidx|
    if dists.has_key?(row) && dists[row].has_key?(col) && row != col
      row_dists << (dists[row][col] / max)
    elsif row == col
      row_dists << 1
    else
      row_dists << 0 # 1 is max distance, so instead of NA make it 1
    end
  end

  puts row_dists.join "\t"
end
