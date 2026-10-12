WITH store_sales_agg AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    s.s_state AS state,
    SUM(ss.ss_net_profit) AS profit,
    0.0 AS loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy, s.s_state
),
catalog_sales_agg AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    ca.ca_state AS state,
    SUM(cs.cs_net_profit) AS profit,
    0.0 AS loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy, ca.ca_state
),
web_sales_agg AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    ca.ca_state AS state,
    SUM(ws.ws_net_profit) AS profit,
    0.0 AS loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy, ca.ca_state
),
store_returns_agg AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    s.s_state AS state,
    0.0 AS profit,
    SUM(sr.sr_net_loss) AS loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy, s.s_state
),
catalog_returns_agg AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    ca.ca_state AS state,
    0.0 AS profit,
    SUM(cr.cr_net_loss) AS loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy, ca.ca_state
),
web_returns_agg AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    ca.ca_state AS state,
    0.0 AS profit,
    SUM(wr.wr_net_loss) AS loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy, ca.ca_state
),
combined AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
  UNION ALL
  SELECT * FROM store_returns_agg
  UNION ALL
  SELECT * FROM catalog_returns_agg
  UNION ALL
  SELECT * FROM web_returns_agg
),
aggregated AS (
  SELECT
    year,
    month,
    state,
    SUM(profit) AS total_profit,
    SUM(loss) AS total_loss,
    SUM(profit) - SUM(loss) AS net_margin
  FROM combined
  GROUP BY year, month, state
)
SELECT
  year,
  month,
  state,
  total_profit,
  total_loss,
  net_margin,
  ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY net_margin DESC) AS profit_rank
FROM aggregated
ORDER BY year, month, net_margin DESC
LIMIT 100
