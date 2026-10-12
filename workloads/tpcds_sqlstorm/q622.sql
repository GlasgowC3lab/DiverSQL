WITH sales_words AS (
    SELECT
        cc.cc_call_center_id,
        word
    FROM catalog_sales cs
    JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    CROSS JOIN UNNEST(regexp_split(lower(regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '')), '\\s+')) AS t(word)
    WHERE cs.cs_sold_date_sk IS NOT NULL
),
word_counts AS (
    SELECT
        cc_call_center_id,
        word,
        COUNT(*) AS word_cnt
    FROM sales_words
    WHERE word <> ''
    GROUP BY cc_call_center_id, word
),
ranked_words AS (
    SELECT
        cc_call_center_id,
        word,
        word_cnt,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY word_cnt DESC, word) AS rn
    FROM word_counts
)
SELECT
    cc.cc_call_center_id,
    upper(cc.cc_name) AS cc_name_upper,
    length(cc.cc_name) - length(replace(cc.cc_name, ' ', '')) AS cc_name_space_count,
    reverse(cc.cc_manager) AS cc_manager_rev,
    length(cc.cc_manager) - length(regexp_replace(cc.cc_manager, '(?i)[aeiou]', '')) AS cc_manager_vowel_cnt,
    array_join(array_agg(concat(rw.word, ':', CAST(rw.word_cnt AS varchar)) ORDER BY rw.word_cnt DESC, rw.word), ', ') AS top_5_words,
    SUM(rw.word_cnt) AS total_word_occurrences
FROM call_center cc
JOIN ranked_words rw ON rw.cc_call_center_id = cc.cc_call_center_id
WHERE rw.rn <= 5
GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_manager
ORDER BY total_word_occurrences DESC
LIMIT 10
