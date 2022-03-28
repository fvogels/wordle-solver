require 'optparse'


class Judge
  def average_information_gained(guess:, candidate_solutions:)
    candidate_solutions.group_by do |candidate_solution|
      s = judge(solution: candidate_solution, guess: guess)
    end.map do |key, words|
      words.size * Math.log2(words.size)
    end.sum.then do |information|
      Math.log2(candidate_solutions.size) - information / candidate_solutions.size
    end
  end


  def find_best_guess(candidate_solutions:, candidate_guesses:)
    candidate_guesses.max_by do |guess|
      average_information_gained(guess: guess, candidate_solutions: candidate_solutions)
    end
  end

  def to_s
    '<JUDGE>'
  end

  def inspect
    to_s
  end
end


class CachedJudge < Judge
  def initialize(filename)
    @table = Marshal.load(IO.binread(filename))
  end

  def judge(solution:, guess:)
    @table["#{solution}:#{guess}"]
  end

  def words
    @words ||= @table.keys.map { |k| k.split(':')[0] }.uniq
  end
end


class StandardJudge < Judge
  def judge(solution:, guess:)
    solution = solution.chars
    guess = guess.chars
    freqs = solution.tally
    result = [ :wrong ] * solution.size

    (0...solution.size).zip(solution, guess).each do |index, expected, actual|
      if expected == actual
        result[index] = :correct
        freqs[expected] -= 1
        if freqs[expected] == 0
          freqs.delete expected
        end
      end
    end

    (0...solution.size).each do |index|
      if freqs.has_key?(guess[index]) && result[index] == :wrong
        result[index] = :misplaced
        freqs[guess[index]] -= 1
        if freqs[guess[index]] == 0
          freqs.delete guess[index]
        end
      end
    end

    result
  end
end


def judgement_id(judgement)
  judgement.chars.map do |x|
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
end


def unparse_judgement(id)
  id.to_s(3).rjust(5, '0').chars.map do |c|
    case c
    when '0'
      'W'
    when '1'
      'M'
    when '2'
      'C'
    end
  end.join
end


def parse_judgement(judgement)
  judgement.upcase.chars.reduce(0) do |acc, c|
    k = case c
    when 'W'
      0
    when 'M'
      1
    when 'C'
      2
    end

    acc * 3 + k
  end
end


def parse_command_line_arguments
  options = { judge: StandardJudge.new }

  OptionParser.new do |opts|
    opts.on('-c [FILENAME]', 'Load cached judge (no word list necessary)') do |filename|
      judge = CachedJudge.new(filename)
      options[:judge] = judge
      options[:words] = judge.words
    end

    opts.on('-w [FILENAME]', 'Use word list') do |filename|
      options[:words] = IO.readlines(filename).map(&:strip)
    end
  end.parse!

  options
end


class Solver
  def initialize(judge, words)
    @judge = judge
    @candidates = words
    @dictionary = words
  end

  def self.load_cache(filename)
    judge = CachedJudge.new filename
    words = judge.words
    Solver.new(judge, words)
  end

  def best_guess
    @judge.find_best_guess(candidate_solutions: @candidates, candidate_guesses: @dictionary)
  end

  def update(guess, judgement)
    id = parse_judgement(judgement)

    @candidates = @candidates.select do |candidate|
      @judge.judge(solution: candidate, guess: guess) == id
    end
  end

  def reset
    @candidates = @dictionary
  end

  def to_s
    "<SOLVER>"
  end

  def inspect
    to_s
  end
end


def main
  options = parse_command_line_arguments

  judge = options[:judge]
  words = options[:words]

  abort "ERROR: No judge" unless judge
  abort "ERROR: No words" unless words

  best_guess = judge.find_best_guess(candidate_solutions: words, candidate_guesses: words)
  puts "Best guess: #{best_guess}"
end


main if $0 == __FILE__
