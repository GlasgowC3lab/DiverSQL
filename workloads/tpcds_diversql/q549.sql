WITH sampled_cr AS (
    SELECT *
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
),
union_returns AS (
    SELECT
        r.r_reason_desc,
        cr.cr_return_amount AS return_amount,
        i.i_item_desc,
        c.c_customer_id,
        cr.cr_return_quantity AS return_quantity,
        word
    FROM sampled_cr cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    WHERE regexp_like(i.i_item_desc, '(?i)gift')
      AND cp.cp_type LIKE 'monthly%'

    UNION DISTINCT

    SELECT
        r.r_reason_desc,
        wr.wr_return_amt AS return_amount,
        i.i_item_desc,
        c.c_customer_id,
        wr.wr_return_quantity AS return_quantity,
        word
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    WHERE regexp_like(i.i_item_desc, '(?i)gift')
      AND i.i_color LIKE 'Red%'
)
SELECT
    ur.r_reason_desc,
    sum(ur.return_amount) AS total_return_amount,
    count(*) AS total_rows,
    count(DISTINCT ur.c_customer_id) AS unique_customers,
    (SELECT max(cr_returned_date_sk) FROM catalog_returns) AS max_returned_date_sk
FROM union_returns ur
WHERE EXISTS (
    SELECT 1
    FROM reason r2
    WHERE r2.r_reason_desc = ur.r_reason_desc
      AND regexp_extract(r2.r_reason_desc, '(\\w+)\\s', 1) IS NOT NULL
)
GROUP BY ur.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
