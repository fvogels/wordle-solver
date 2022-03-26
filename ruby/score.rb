def score(solution:, guess:)
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


def score?(expected_score:, solution:, guess:)
  score(solution: solution, guess: guess) == expected_score
end