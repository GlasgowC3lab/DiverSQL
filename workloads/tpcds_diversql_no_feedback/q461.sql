WITH joined AS (
    SELECT
        wr.wr_return_amt,
        i.i_category,
        i.i_item_desc,
        t.t_shift,
        t.t_time_id
    FROM web_returns AS wr
    JOIN item AS i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim AS t ON wr.wr_returned_time_sk = t.t_time_sk
)

SELECT
    i_category,
    t_shift,
    'NUM_SUFFIX' AS desc_type,
    SUM(wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM joined
WHERE regexp_like(i_item_desc, '[0-9]{2,}$')
  AND t_time_id LIKE 'AAAA%'
GROUP BY GROUPING SETS ((i_category, t_shift), (i_category), (t_shift), ())

UNION DISTINCT

SELECT
    i_category,
    t_shift,
    'BRUSH_PATTERN' AS desc_type,
    SUM(wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM joined
WHERE i_item_desc LIKE '%BRUSH%'
  AND regexp_extract(i_item_desc, '(\\w+)$', 1) = 'red'
GROUP BY GROUPING SETS ((i_category, t_shift), (i_category), (t_shift), ())

ORDER BY total_return_amount DESC
LIMIT 100
