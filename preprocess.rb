require_relative 'score'


dictionary = STDIN.readlines.map(&:strip)


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

    puts "#{solution} #{guess} #{s}"
  end
end
