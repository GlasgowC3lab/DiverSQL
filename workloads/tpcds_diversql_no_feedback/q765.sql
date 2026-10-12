WITH sr AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_store_sk,
    sr.sr_item_sk,
    sr.sr_reason_sk,
    sr.sr_net_loss,
    i.i_item_desc,
    i.i_manager_id,
    s.s_store_name,
    r.r_reason_desc
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE
    regexp_like(i.i_item_desc, '^[A-Za-z]{5,}')
    AND s.s_store_name LIKE '%Store%'
    AND CAST(i.i_manager_id AS varchar) = substr(i.i_item_id, 1, 2)
)
SELECT
  s_store_name,
  r_reason_desc,
  regexp_extract(i_item_desc, '(\\w+)', 1) || '_' || CAST(i_manager_id AS varchar) AS item_key,
  sum(sr_net_loss) AS total_net_loss,
  count(*) AS return_cnt
FROM sr
WHERE sr_ticket_number NOT IN (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_amt > 200
)
GROUP BY
  s_store_name,
  r_reason_desc,
  regexp_extract(i_item_desc, '(\\w+)', 1) || '_' || CAST(i_manager_id AS varchar)
ORDER BY total_net_loss DESC
LIMIT 100
