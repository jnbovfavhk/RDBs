import time
from concurrent.futures import ProcessPoolExecutor
from idlelib.iomenu import encoding

from pyxdameraulevenshtein import damerau_levenshtein_distance as dam_lev_dist

a = "морок"
b = "молоко"


def write_to_output(s, output=None):
    if output is None:
        print(s)
    else:
        output.write(s + "\n")


def find_string_with_2_corrections(querie_word, dict_word, writing_file=None):
    # Для замены и неправильно введенной буквы
    if len(querie_word) == len(dict_word):
        for i in range(len(querie_word)):

            if querie_word[i] != dict_word[i]:
                # Если не равен не последний символ, пробуем замену
                if i != len(dict_word) - 1:
                    # Если ожидаемая замена соседних не в конце
                    if i != len(dict_word) - 2:
                        # Если замена соседних работает
                        if dict_word[i + 1] + dict_word[i] == querie_word[i:i + 2]:

                            ans = querie_word[:i] + querie_word[i + 1] + querie_word[i] + querie_word[i + 2:]

                            return querie_word + " 2 " + ans + " " + dict_word


                        # Если не работает, значит был неправильно введен символ
                        else:

                            ans = querie_word[:i] + dict_word[i] + querie_word[i + 1:]

                            return querie_word + " 2 " + ans + " " + dict_word
                    # Если в конце
                    else:
                        if dict_word[i + 1] + dict_word[i] == querie_word[i:i + 2]:

                            ans = querie_word[:i] + querie_word[i + 1] + querie_word[i:]
                            return querie_word + " 2 " + ans + " " + dict_word
                        # Если не работает, значит был неправильно введен символ
                        else:
                            ans = querie_word[:i] + dict_word[i] + querie_word[i + 1:]
                            return querie_word + " 2 " + ans + " " + dict_word
                # Если в конце неравные символы, значит он неправильно введен
                else:
                    ans = querie_word[:i] + dict_word[i]
                    return querie_word + " 2 " + ans + " " + dict_word

    # Если длина неправильного слова больше длины правильного, пробуем удалить каждый символ и ищем расстояние левенштейна
    elif len(querie_word) > len(dict_word):
        for i in range(len(querie_word)):
            # Если символ не последний
            if i != len(querie_word) - 1:
                mid_word = querie_word[:i] + querie_word[i + 1:]
                if dam_lev_dist(mid_word, querie_word) == 1 and dam_lev_dist(mid_word, dict_word) == 1:

                    return querie_word + " 2 " + mid_word + " " + dict_word
            # Если последний
            else:
                mid_word = querie_word[:i]
                if dam_lev_dist(mid_word, querie_word) == 1 and dam_lev_dist(mid_word, dict_word) == 1:
                    return querie_word + " 2 " + mid_word + " " + dict_word

    # Если длина правильного больше длины неправильного, пробуем удалить из правильного
    elif len(querie_word) < len(dict_word):
        for i in range(len(dict_word)):
            # Если символ не последний
            if i != len(dict_word) - 1:
                mid_word = dict_word[:i] + dict_word[i + 1:]
                if dam_lev_dist(mid_word, querie_word) == 1 and dam_lev_dist(mid_word, dict_word) == 1:
                    return querie_word + " 2 " + mid_word + " " + dict_word
            # Если последний
            else:
                mid_word = dict_word[:i]
                if dam_lev_dist(mid_word, querie_word) == 1 and dam_lev_dist(mid_word, dict_word) == 1:
                    return querie_word + " 2 " + mid_word + " " + dict_word

def process_item(word, dict):

    word = word.strip()
    for dict_word in dict:
        distance = dam_lev_dist(dict_word, word)
        if distance == 0:
            return f"{word} 0"
        elif distance == 1:
            return f"{word} 1 {dict_word}"
        elif distance == 2:
            return find_string_with_2_corrections(word, dict_word)
    return f"{word} 3+"


def solve(dict_file, queries_file, output_file):
    with open(dict_file, "r", encoding="UTF-8") as f:
        dict = f.read().split()


    with open(queries_file, "r", encoding="UTF-8") as f:
        # word = f.readline().strip("\n")
        # words = f.readlines()



        with ProcessPoolExecutor(max_workers=7) as executor:
            words = f.readlines()
            results = list(executor.map(process_item, words, [dict]*len(words)))
    with open(output_file, "w", encoding="UTF-8") as f:
        f.write("\n".join(results))


        # while word != "":

        # pair_found = False
        #
        # for i in range(len(dict)):
        #     if dam_lev_dist(dict[i], word) == 0:
        #         # print(word + " 0")
        #         write_to_output(word + " 0", output=output)
        #         pair_found = True
        #         break
        #     elif dam_lev_dist(dict[i], word) == 1:
        #         # print(word + " 1 " + dict[i])
        #         write_to_output(word + " 1 " + dict[i], output=output)
        #         pair_found = True
        #         break
        #     elif dam_lev_dist(dict[i], word) == 2:
        #         print_with_2_corrections(querie_word=word, dict_word=dict[i], writing_file=output)
        #         pair_found = True
        #         break
        # if not pair_found:
        #     write_to_output(word + " 3+", output=output)
        # word = f.readline().strip("\n")

if __name__ == '__main__':
    start_time = time.time()
    solve("dict.txt", "test_queries", "output_file.txt")
    print("--- %s seconds ---" % (time.time() - start_time))
