WITH item_extracted AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_item_desc,
        regexp_extract(i_item_id, '(\\d+)', 1) AS item_numeric_id
    FROM item
    WHERE regexp_like(i_item_desc, '(?i)premium')
)
SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    i_ex.item_numeric_id,
    i_ex.i_item_desc,
    r.r_reason_desc,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN item_extracted i_ex
    ON wr.wr_item_sk = i_ex.i_item_sk
JOIN customer c
    ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE r.r_reason_desc LIKE '%damaged%'
  AND substr(c.c_email_address, 1, 3) = 'abc'
GROUP BY d.d_year, d.d_month_seq, i_ex.item_numeric_id, i_ex.i_item_desc, r.r_reason_desc
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
