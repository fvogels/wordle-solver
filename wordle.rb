# SCORES_FILENAME = 'scores.txt'
# SCORES_FILENAME = 'scores.bin'
# SCORES_FILENAME = 'scores-light.bin'
SCORES_FILENAME = 'testwords.bin'
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


def information_gained(guess_score:, guess:, candidate_solutions:)
  compatible_count = candidate_solutions.count do |candidate_solution|
    score(solution: candidate_solution, guess: guess) == guess_score
  end

  incompatible_count = candidate_solutions.size - compatible_count

  original_information_necessary = Math.log2(candidate_solutions.size)
  average_information_after_guess =
    (
      (compatible_count > 0 ? compatible_count * Math.log2(compatible_count) : 0) +
      (incompatible_count > 0 ? incompatible_count * Math.log2(incompatible_count) : 0)
    ) / candidate_solutions.size

  result = original_information_necessary - average_information_after_guess

  # STDERR.puts "Guess=#{guess} Score=#{unparse_score(guess_score)} Original=#{original_information_necessary} After=#{average_information_after_guess} #{candidate_solutions.size}=#{compatible_count}+#{incompatible_count}"

  result
end


def average_information_gained(guess:, candidate_solutions:)
  candidate_solutions.map do |candidate_solution|
    s = score(solution: candidate_solution, guess: guess)
    information_gained(guess_score: s, guess: guess, candidate_solutions: candidate_solutions)
  end.sum / candidate_solutions.size
end


def find_best_guess(candidate_solutions:, candidate_guesses:)
  count = 0
  candidate_guesses.max_by do |candidate_guess|
    count += 1
    if count % 10 == 0
      STDERR.puts "#{count * 100 / candidate_guesses.size}%"
    end

    average_information_gained(guess: candidate_guess, candidate_solutions: candidate_solutions)
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
