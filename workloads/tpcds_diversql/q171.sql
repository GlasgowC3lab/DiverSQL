/*
  Goal: Rank customers (and their associated store) by total net loss from both store and web returns, classifying loss severity, and show the previous total net loss per customer.
*/
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  s.s_store_name,
  sr.sr_returned_date_sk,
  sr.sr_return_amt,
  wr.wr_return_amt,
  COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) AS total_net_loss,
  CASE
    WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 1000 THEN 'High'
    WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 500  THEN 'Medium'
    ELSE 'Low'
  END AS loss_category,
  RANK() OVER (ORDER BY (COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) DESC) AS loss_rank,
  LAG(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0))
    OVER (PARTITION BY c.c_customer_sk ORDER BY sr.sr_returned_date_sk) AS prev_total_net_loss
FROM
  store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN "store" s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd_wr ON wr.wr_returning_cdemo_sk = cd_wr.cd_demo_sk
  LEFT JOIN household_demographics hd_wr ON wr.wr_returning_hdemo_sk = hd_wr.hd_demo_sk
  LEFT JOIN customer_address ca_wr ON wr.wr_returning_addr_sk = ca_wr.ca_address_sk
WHERE
  c.c_birth_year BETWEEN 1960 AND 1980
  AND cd.cd_purchase_estimate >= 3000
  AND hd.hd_vehicle_count >= 1
  AND s.s_state = 'CA'
  AND ca.ca_country = 'United States'
  AND sr.sr_return_amt > 100
  AND (wr.wr_return_amt > 50 OR wr.wr_return_amt IS NULL)
ORDER BY
  loss_rank,
  c.c_customer_id
LIMIT 100
