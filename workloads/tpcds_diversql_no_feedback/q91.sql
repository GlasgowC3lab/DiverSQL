WITH sr AS (
    SELECT sr.sr_store_sk,
           sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_amt
    FROM store_returns sr
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = sr.sr_item_sk
          AND wr.wr_returned_date_sk = sr.sr_returned_date_sk
    )
)
SELECT
    s.s_store_name,
    d.d_year,
    SUM(sr.sr_return_amt) AS total_return_amount,
    CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_category,
    CONCAT('Store_', CAST(s.s_store_sk AS VARCHAR)) AS store_key,
    REGEXP_EXTRACT(i.i_item_desc, '(\\w+)$') AS item_desc_suffix
FROM sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE s.s_store_name LIKE '%Market%'
  AND REGEXP_LIKE(i.i_item_desc, '^.*[0-9]{2}.*$')
GROUP BY s.s_store_name, d.d_year, s.s_store_sk, i.i_item_desc
ORDER BY total_return_amount DESC
LIMIT 100
