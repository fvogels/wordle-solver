require_relative 'wordle'


def test_score
  [
    [ "abcde", "abcde", "CCCCC" ],
    [ "abcde", "xxxxx", "WWWWW" ],
    [ "abcde", "edcba", "MMCMM" ],
  ].each do |solution, guess, expected_score|
    expected_score.chars.map do |c|
      case c
      when 'C'
        :correct
      when 'M'
        :misplaced
      when 'W'
        :wrong
      end
    end.then do |expected_score|
      actual_score = score(solution: solution, guess: guess)

      unless actual_score == expected_score
        puts <<~END
          FAILURE on score(#{solution}, #{guess})
          Expected: #{expected_score}
          Actual: #{actual_score}
        END
        abort
      end
    end
  end
end


test_score
