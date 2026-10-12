WITH sales_all AS (
  SELECT ss_sold_date_sk AS sold_date_sk,
         ss_sold_time_sk AS sold_time_sk,
         ss_item_sk AS item_sk,
         ss_customer_sk AS customer_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_sold_time_sk,
         cs_item_sk,
         cs_bill_customer_sk,
         cs_quantity,
         cs_net_paid_inc_tax,
         cs_net_profit,
         'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_sold_time_sk,
         ws_item_sk,
         ws_bill_customer_sk,
         ws_quantity,
         ws_net_paid_inc_tax,
         ws_net_profit,
         'web'
  FROM web_sales
), returns_all AS (
  SELECT sr_returned_date_sk AS return_date_sk,
         sr_return_time_sk AS return_time_sk,
         sr_item_sk AS item_sk,
         sr_customer_sk AS customer_sk,
         sr_return_quantity AS quantity,
         sr_refunded_cash AS return_amount,
         sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns
  UNION ALL
  SELECT cr_returned_date_sk,
         cr_returned_time_sk,
         cr_item_sk,
         cr_returning_customer_sk,
         cr_return_quantity,
         cr_refunded_cash,
         cr_net_loss,
         'catalog'
  FROM catalog_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_returned_time_sk,
         wr_item_sk,
         wr_returning_customer_sk,
         wr_return_quantity,
         wr_refunded_cash,
         wr_net_loss,
         'web'
  FROM web_returns
), sales_agg AS (
  SELECT
    s.customer_sk,
    COALESCE(custom.c_customer_id, CAST(s.customer_sk AS VARCHAR)) AS c_customer_id,
    ca.ca_state,
    d.d_year,
    d.d_month_seq,
    s.channel,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_paid) AS total_paid,
    SUM(s.net_profit) AS total_profit
  FROM sales_all s
  LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
  LEFT JOIN customer custom ON s.customer_sk = custom.c_customer_sk
  LEFT JOIN customer_address ca ON custom.c_current_addr_sk = ca.ca_address_sk
  GROUP BY
    s.customer_sk,
    COALESCE(custom.c_customer_id, CAST(s.customer_sk AS VARCHAR)),
    ca.ca_state,
    d.d_year,
    d.d_month_seq,
    s.channel
), returns_agg AS (
  SELECT
    r.customer_sk,
    COALESCE(custom.c_customer_id, CAST(r.customer_sk AS VARCHAR)) AS c_customer_id,
    ca.ca_state,
    d.d_year,
    d.d_month_seq,
    r.channel,
    SUM(r.quantity) AS total_quantity,
    SUM(r.return_amount) AS total_return_amount
  FROM returns_all r
  LEFT JOIN date_dim d ON r.return_date_sk = d.d_date_sk
  LEFT JOIN customer custom ON r.customer_sk = custom.c_customer_sk
  LEFT JOIN customer_address ca ON custom.c_current_addr_sk = ca.ca_address_sk
  GROUP BY
    r.customer_sk,
    COALESCE(custom.c_customer_id, CAST(r.customer_sk AS VARCHAR)),
    ca.ca_state,
    d.d_year,
    d.d_month_seq,
    r.channel
), combined AS (
  SELECT
    COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
    COALESCE(s.c_customer_id, r.c_customer_id) AS c_customer_id,
    COALESCE(s.ca_state, r.ca_state) AS ca_state,
    COALESCE(s.d_year, r.d_year) AS d_year,
    COALESCE(s.d_month_seq, r.d_month_seq) AS d_month_seq,
    COALESCE(s.channel, r.channel) AS channel,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_paid, 0) AS total_paid,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(r.total_quantity, 0) AS return_quantity,
    COALESCE(r.total_return_amount, 0) AS return_amount,
    (COALESCE(s.total_paid, 0) - COALESCE(r.total_return_amount, 0)) AS net_sales_amount,
    CASE WHEN COALESCE(s.total_paid, 0) = 0 THEN NULL ELSE s.total_profit / NULLIF(s.total_paid, 0) END AS profit_margin,
    CONCAT(COALESCE(s.c_customer_id, 'UNKNOWN'), '-', CAST(COALESCE(s.d_year, 0) AS VARCHAR), '-', CAST(COALESCE(s.d_month_seq, 0) AS VARCHAR), '-', COALESCE(s.channel, 'NONE')) AS metric_id,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(s.d_year, r.d_year), COALESCE(s.d_month_seq, r.d_month_seq) ORDER BY COALESCE(s.total_profit, 0) DESC) AS profit_rank,
    SUM(COALESCE(s.total_profit, 0)) OVER (PARTITION BY COALESCE(s.ca_state, r.ca_state)) AS state_total_profit,
    (SELECT MAX(sub.total_profit) FROM sales_agg sub WHERE sub.channel = COALESCE(s.channel, r.channel) AND sub.customer_sk <> COALESCE(s.customer_sk, r.customer_sk)) AS max_other_profit_same_channel
  FROM sales_agg s
  FULL OUTER JOIN returns_agg r
    ON s.customer_sk = r.customer_sk
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.channel = r.channel
)
SELECT
  customer_sk,
  c_customer_id,
  ca_state,
  d_year,
  d_month_seq,
  channel,
  total_quantity,
  total_paid,
  total_profit,
  return_quantity,
  return_amount,
  net_sales_amount,
  profit_margin,
  metric_id,
  profit_rank,
  state_total_profit,
  max_other_profit_same_channel
FROM combined
UNION ALL
SELECT
  -1 AS customer_sk,
  'OVERALL' AS c_customer_id,
  NULL AS ca_state,
  NULL AS d_year,
  NULL AS d_month_seq,
  'OVERALL' AS channel,
  SUM(total_quantity) AS total_quantity,
  SUM(total_paid) AS total_paid,
  SUM(total_profit) AS total_profit,
  SUM(return_quantity) AS return_quantity,
  SUM(return_amount) AS return_amount,
  SUM(net_sales_amount) AS net_sales_amount,
  NULL AS profit_margin,
  'OVERALL-METRIC' AS metric_id,
  NULL AS profit_rank,
  NULL AS state_total_profit,
  NULL AS max_other_profit_same_channel
FROM combined
WHERE profit_margin IS NOT NULL OR total_quantity > 0
