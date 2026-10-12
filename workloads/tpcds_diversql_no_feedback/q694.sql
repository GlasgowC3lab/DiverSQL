WITH item_words AS (
    SELECT 
        i.i_item_sk,
        i.i_manager_id,
        i.i_category,
        i.i_item_desc,
        split(i.i_item_desc, ' ') AS words
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '(?i)large|small')
),
item_word_rows AS (
    SELECT 
        iw.i_item_sk,
        iw.i_manager_id,
        iw.i_category,
        word
    FROM item_words iw
    CROSS JOIN UNNEST(iw.words) AS t(word)
    WHERE word <> ''
),
returns AS (
    SELECT 
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt AS return_amt,
        'store' AS channel
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_manager_id IS NOT NULL
    UNION ALL
    SELECT 
        wr.wr_item_sk,
        wr.wr_return_amt,
        'web' AS channel
    FROM tpcds.web_returns wr
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_manager_id IS NOT NULL
    UNION ALL
    SELECT 
        cr.cr_item_sk,
        cr.cr_return_amount,
        'catalog' AS channel
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_manager_id IS NOT NULL
)
SELECT 
    iwr.i_manager_id,
    iwr.i_category,
    iwr.word,
    r.channel,
    COUNT(*) AS return_cnt,
    SUM(r.return_amt) AS total_return_amount
FROM returns r
JOIN item_word_rows iwr ON r.item_sk = iwr.i_item_sk
WHERE iwr.word LIKE 'A%'
GROUP BY GROUPING SETS (
    (iwr.i_manager_id, iwr.i_category, iwr.word, r.channel),
    (iwr.i_manager_id, iwr.i_category, r.channel),
    (iwr.word, r.channel),
    (r.channel)
)
ORDER BY total_return_amount DESC
LIMIT 100
