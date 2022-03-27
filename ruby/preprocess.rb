require 'optparse'
require_relative 'score'


def build_table(dictionary)
  table = {}

  dictionary.each do |solution|
    dictionary.each do |guess|
      s = score(solution: solution, guess: guess).map do |x|
        case x
        when :correct
          2
        when :misplaced
          1
        when :wrong
          0
        end
      end.reduce(0) do |acc, n|
        acc * 3 + n
      end

      table["#{solution}:#{guess}"] = s.to_i
    end
  end

  table
end

def write_binary(table, filename)
  abort "Cannot write binary to STDOUT" if filename == :stdout

  binary = Marshal.dump(table)
  IO.binwrite(filename, binary)
end

def write_compressed(table, filename)
  abort "Cannot write binary to STDOUT" if filename == :stdout

  words = table.keys.map { |key| key[0...5] }.uniq.sort

  File.open(filename, 'wb') do |file|
    file.write([words.size].pack('L'))

    words.map do |word|
      id = word.chars.reduce(0) do |acc, letter|
        acc * 26 + (letter.ord - 'a'.ord)
      end
    end.then do |data|
      file.write(data.pack('L*'))
    end

    words.flat_map do |solution|
      words.map do |guess|
        key = "#{solution}:#{guess}"
        score = table[key]
      end
    end.then do |data|
      file.write(data.pack('C*'))
    end
  end
end

def write_text(table, filename)
  file = filename == :stdout ? STDOUT : File.open(filename, 'w')

  table.each do |key, value|
    file.puts "#{key}:#{value}"
  end

  file.close unless filename == :stdout
end

def write(table, filename, mode)
  case mode
  when :text
    write_text(table, filename)
  when :binary
    write_binary(table, filename)
  when :compressed
    write_compressed(table, filename)
  end
end


options = { mode: :text, output: :stdout }
OptionParser.new do |opts|
  opts.on('-b', '--binary', 'Output in binary') do
    options[:mode] = :binary
  end

  opts.on('-c', '--compressed', 'Compressed output') do
    options[:mode] = :compressed
  end

  opts.on('-o [FILE]', 'Output file') do |filename|
    options[:output] = filename
  end
end.parse!

dictionary = STDIN.readlines.map(&:strip)
table = build_table(dictionary)
write(table, options[:output], options[:mode])
