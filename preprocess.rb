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
  IO.write(filename, binary)
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
  end
end


options = { mode: :text, output: :stdout }
OptionParser.new do |opts|
  opts.on('-b', '--binary', 'Output in binary') do
    options[:mode] = :binary
  end

  opts.on('-o [FILE]', 'Output file') do |filename|
    options[:output] = filename
  end
end.parse!

dictionary = STDIN.readlines.map(&:strip)
table = build_table(dictionary)
write(table, options[:output], options[:mode])
