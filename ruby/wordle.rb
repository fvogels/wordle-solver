# SCORES_FILENAME = 'scores.txt'
SCORES_FILENAME = 'scores.bin'
# SCORES_FILENAME = 'scores-light.bin'
# SCORES_FILENAME = 'testwords.bin'
# SCORES_FILENAME = 'scores-light.txt'

def unparse_score(n)
  n.to_s(3).rjust(5, '0').chars.map do |c|
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

def load_score_table(filename, mode)
  case mode
  when :binary
    Marshal.load(IO.binread(filename))

  when :text
    abort "Not supported yet"
  end
  # table = Hash.new do |h, k|
  #   h[k] = {}
  # end

  # IO.readlines(SCORES_FILENAME).each do |line|
  #   solution, guess, score = line.strip.split

  #   table[solution][guess] = score.to_i
  # end

  # table
end

STDERR.puts "Loading scores..."
$score_table = load_score_table(SCORES_FILENAME, :binary)
$dictionary = $score_table.keys.map { |k| k.split(':')[0] }.uniq
STDERR.puts "Done!"

def score(solution:, guess:)
  $score_table["#{solution}:#{guess}"]
end


def average_information_gained(guess:, candidate_solutions:)
  candidate_solutions.group_by do |candidate_solution|
    s = score(solution: candidate_solution, guess: guess)
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


def main
  best_guess = find_best_guess(candidate_solutions: $dictionary, candidate_guesses: $dictionary)
  puts "Best guess: #{best_guess}"
end

def test
  dictionary = $dictionary

  # dictionary.each do |guess|
  #   s = score(solution: 'stake', guess: guess)
  #   p information_gained(guess_score: s, guess: guess, candidate_solutions: dictionary)
  # end

  puts find_best_guess(candidate_solutions: dictionary, candidate_guesses: dictionary)
end

main

# main if $0 == __FILE__
# test if $0 == __FILE__
