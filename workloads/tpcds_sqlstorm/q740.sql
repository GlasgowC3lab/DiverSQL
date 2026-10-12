SELECT
  state,
  year,
  SUM(amount) AS total_profit
FROM (
  SELECT
    s.s_state AS state,
    d.d_year AS year,
    ss.ss_net_profit AS amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk

  UNION ALL

  SELECT
    ca.ca_state AS state,
    d2.d_year AS year,
    ws.ws_net_profit AS amount
  FROM web_sales ws
  JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
  JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
  JOIN customer_address ca ON c2.c_current_addr_sk = ca.ca_address_sk

  UNION ALL

  SELECT
    ca2.ca_state AS state,
    d3.d_year AS year,
    cs.cs_net_profit AS amount
  FROM catalog_sales cs
  JOIN date_dim d3 ON cs.cs_sold_date_sk = d3.d_date_sk
  JOIN customer c3 ON cs.cs_bill_customer_sk = c3.c_customer_sk
  JOIN customer_address ca2 ON c3.c_current_addr_sk = ca2.ca_address_sk

  UNION ALL

  SELECT
    s2.s_state AS state,
    dr.d_year AS year,
    -sr.sr_net_loss AS amount
  FROM store_returns sr
  JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
  JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk

  UNION ALL

  SELECT
    ca3.ca_state AS state,
    dr2.d_year AS year,
    -wr.wr_net_loss AS amount
  FROM web_returns wr
  JOIN date_dim dr2 ON wr.wr_returned_date_sk = dr2.d_date_sk
  JOIN customer c4 ON wr.wr_refunded_customer_sk = c4.c_customer_sk
  JOIN customer_address ca3 ON c4.c_current_addr_sk = ca3.ca_address_sk

  UNION ALL

  SELECT
    ca4.ca_state AS state,
    dr3.d_year AS year,
    -cr.cr_net_loss AS amount
  FROM catalog_returns cr
  JOIN date_dim dr3 ON cr.cr_returned_date_sk = dr3.d_date_sk
  JOIN customer c5 ON cr.cr_refunded_customer_sk = c5.c_customer_sk
  JOIN customer_address ca4 ON c5.c_current_addr_sk = ca4.ca_address_sk
) t
GROUP BY
  state,
  year
ORDER BY
  total_profit DESC
LIMIT 100
