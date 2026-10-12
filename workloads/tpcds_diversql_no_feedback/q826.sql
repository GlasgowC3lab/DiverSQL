WITH filtered_stores AS (
    SELECT s_store_sk,
           s_store_name,
           s_city,
           s_state
    FROM store
    WHERE s_state LIKE 'A%'
)
SELECT
    ds.d_year,
    fs.s_city AS store_city,
    r.r_reason_desc,
    regexp_extract(r.r_reason_desc, '^([^ ]+)', 1) AS reason_first_word,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    COUNT(*) AS num_returns
FROM store_returns sr
JOIN date_dim ds
  ON sr.sr_returned_date_sk = ds.d_date_sk
JOIN filtered_stores fs
  ON sr.sr_store_sk = fs.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ds.d_fy_year = 1912
  AND regexp_like(fs.s_store_name, '^A.*')
  AND ca.ca_city LIKE CONCAT(fs.s_city, '%')
  AND sr.sr_store_sk IN (SELECT s_store_sk FROM store WHERE s_state LIKE 'A%')
GROUP BY ds.d_year,
         fs.s_city,
         r.r_reason_desc,
         regexp_extract(r.r_reason_desc, '^([^ ]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
