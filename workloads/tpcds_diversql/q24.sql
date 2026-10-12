WITH store_metrics AS (
  SELECT
    ca.ca_state,
    c.c_customer_id,
    SUM(ss.ss_net_profit) AS total_profit,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ss.ss_net_profit) DESC) AS rnk
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND EXISTS (
      SELECT 1
      FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_type = 'product'
    )
  GROUP BY ca.ca_state, c.c_customer_id
),
store_top AS (
  SELECT ca_state, c_customer_id, total_profit, rnk
  FROM store_metrics
  WHERE rnk <= 3
),
web_metrics AS (
  SELECT
    ca.ca_state,
    c.c_customer_id,
    SUM(wr.wr_net_loss) AS total_loss,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(wr.wr_net_loss) DESC) AS rnk
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND EXISTS (
      SELECT 1
      FROM catalog_page cp
      WHERE cp.cp_type = 'promo'
        AND cp.cp_start_date_sk <= d.d_date_sk
        AND cp.cp_end_date_sk >= d.d_date_sk
    )
  GROUP BY ca.ca_state, c.c_customer_id
),
web_top AS (
  SELECT ca_state, c_customer_id, total_loss, rnk
  FROM web_metrics
  WHERE rnk <= 3
)
SELECT
  'store' AS source,
  st.ca_state,
  st.c_customer_id,
  st.total_profit AS metric,
  st.rnk
FROM store_top st
UNION ALL
SELECT
  'web' AS source,
  wt.ca_state,
  wt.c_customer_id,
  wt.total_loss AS metric,
  wt.rnk
FROM web_top wt
ORDER BY ca_state, metric DESC
LIMIT 100
