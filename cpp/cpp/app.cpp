#include <algorithm>
#include <iostream>
#include <fstream>
#include <cstdint>
#include <memory>
#include <chrono>
#include <string>
#include <vector>
#include <math.h>
#include <map>
#include <set>


typedef uint32_t wordid;
typedef uint8_t  scoreid;


std::string to_word(wordid id)
{
    char buffer[6];

    buffer[5] = 0;
    for (int i = 4; i >= 0; i--)
    {
        buffer[i] = 'a' + id % 26;
        id = id / 26;
    }

    return std::string(buffer);
}

std::string to_score(scoreid id)
{
    char buffer[6];

    buffer[5] = 0;
    for (int i = 4; i >= 0; i--)
    {
        char c = '?';

        switch (id % 3)
        {
        case 2:
            c = 'C';
            break;
        case 1:
            c = 'M';
            break;
        case 0:
            c = 'W';
            break;
        }

        id /= 3;
        buffer[i] = c;
    }

    return std::string(buffer);
}

class Scorer
{
private:
    typedef uint64_t key;

    std::set<wordid> words;

    std::map<key, scoreid> table;

    key derive_key(wordid solution, wordid guess) const
    {
        return (uint64_t(solution) << 32) | uint64_t(guess);
    }

public:
    void add(wordid solution, wordid guess, scoreid score)
    {
        words.insert(solution);
        key id = derive_key(solution, guess);
        table[id] = score;
    }

    scoreid lookup(wordid solution, wordid guess) const
    {
        key id = derive_key(solution, guess);
        return table.find(id)->second;
    }

    const std::set<wordid>& wordids() const
    {
        return words;
    }
};


Scorer load_scorer(const std::string& path)
{
    Scorer scorer;
    std::ifstream file(path, std::ios::binary);

    uint32_t word_count;
    file.read(reinterpret_cast<char*>(&word_count), sizeof(word_count));

    auto words = std::make_unique<wordid[]>(word_count);
    file.read(reinterpret_cast<char*>(words.get()), sizeof(wordid) * word_count);

    auto table = std::make_unique<scoreid[]>(word_count * word_count);
    file.read(reinterpret_cast<char*>(table.get()), sizeof(scoreid) * word_count * word_count);

    uint32_t index = 0;
    for (uint32_t i = 0; i != word_count; ++i)
    {
        auto solution = words[i];

        for (uint32_t j = 0; j != word_count; ++j)
        {
            auto guess = words[j];

            scorer.add(solution, guess, table[index]);

            index++;
        }
    }

    return scorer;
}

template<typename T>
double measure_information_gained(const Scorer& scorer, scoreid score, wordid guess, const T& candidate_solutions)
{
    unsigned compatible_count = 0;
    unsigned incompatible_count = 0;
    auto it = candidate_solutions.begin();
    auto end = candidate_solutions.end();

    while (it != end)
    {
        wordid candidate = *it;

        if (scorer.lookup(candidate, guess) == score)
        {
            ++compatible_count;
        }
        else
        {
            ++incompatible_count;
        }

        it++;
    }

    auto total = compatible_count + incompatible_count;
    double information = total * log2(total);

    if (compatible_count > 0)
    {
        information -= compatible_count * log2(compatible_count);
    }

    if (incompatible_count > 0)
    {
        information -= incompatible_count * log2(incompatible_count);
    }

    return information / total;
}

template<typename T>
double average_information_gained(const Scorer& scorer, wordid guess, const T& candidate_solutions)
{
    double table[243];
    double total_information = 0;
    unsigned count = 0;

    std::fill_n(table, 243, -1);

    for (auto& candidate_solution : candidate_solutions)
    {
        auto score = scorer.lookup(candidate_solution, guess);

        if (table[score] == -1)
        {
            table[score] = measure_information_gained(scorer, score, guess, candidate_solutions);
        }
        
        total_information += table[score];
        count++;
    }

    return total_information / count;
}


template<typename T>
wordid find_best_guess(const Scorer& scorer, const T& candidate_solutions, const T& candidate_guesses)
{
    double most_information_gained = 0;
    wordid best_guess = 0;
    unsigned progress = 0;
    auto start_time = std::chrono::steady_clock::now();

    for (auto& guess : candidate_guesses)
    {
        auto information = average_information_gained(scorer, guess, candidate_guesses);

        if (information > most_information_gained)
        {
            most_information_gained = information;
            best_guess = guess;
        }

        progress++;
        
        {
            auto current_time = std::chrono::steady_clock::now();
            auto time_passed = std::chrono::duration_cast<std::chrono::seconds>(current_time - start_time);
            auto progress_percentage = double(progress) / candidate_guesses.size();
            auto estimated_duration = time_passed / progress_percentage;
            auto time_left = estimated_duration - time_passed;

            std::cout << (progress_percentage * 100) << "% done in " << time_passed.count() << "s; estimated total duration: " << (estimated_duration.count() / 60) << "m, " << (time_left.count() / 60) << "m left" << std::endl;
        }
    }

    return best_guess;
}

int main()
{
    auto scorer = load_scorer(R"(G:\repos\wordle\scores.compressed)");
    auto& words = scorer.wordids();
    auto best_guess = find_best_guess(scorer, words, words);

    std::cout << to_word(best_guess) << std::endl;
}