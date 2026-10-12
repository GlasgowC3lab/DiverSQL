WITH date_qtr AS (
  SELECT d_date_sk, d_year, d_quarter_seq
  FROM date_dim
  WHERE d_year = 2001
    AND d_quarter_seq = (
      SELECT MAX(d_quarter_seq) FROM date_dim WHERE d_year = 2001
    )
),
quarter_info AS (
  SELECT d_year, d_quarter_seq
  FROM date_qtr
  LIMIT 1
),
store_sales_agg AS (
  SELECT
    ss.ss_customer_sk AS c_customer_sk,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
  FROM store_sales ss
  JOIN date_qtr dq ON ss.ss_sold_date_sk = dq.d_date_sk
  GROUP BY ss.ss_customer_sk
),
web_sales_agg AS (
  SELECT
    ws.ws_bill_customer_sk AS c_customer_sk,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM web_sales ws
  JOIN date_qtr dq ON ws.ws_sold_date_sk = dq.d_date_sk
  GROUP BY ws.ws_bill_customer_sk
),
store_returns_agg AS (
  SELECT
    sr.sr_customer_sk AS c_customer_sk,
    SUM(sr.sr_net_loss) AS store_net_loss
  FROM store_returns sr
  JOIN date_qtr dq ON sr.sr_returned_date_sk = dq.d_date_sk
  GROUP BY sr.sr_customer_sk
),
web_returns_agg AS (
  SELECT
    wr.wr_refunded_customer_sk AS c_customer_sk,
    SUM(wr.wr_net_loss) AS web_net_loss
  FROM web_returns wr
  JOIN date_qtr dq ON wr.wr_returned_date_sk = dq.d_date_sk
  GROUP BY wr.wr_refunded_customer_sk
),
customer_info AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    COALESCE(c.c_first_name,'') || ' ' || COALESCE(c.c_last_name,'') AS cust_name
  FROM customer c
),
combined_sales AS (
  SELECT
    ci.c_customer_sk,
    ci.c_customer_id,
    ci.cust_name,
    qi.d_year,
    qi.d_quarter_seq,
    COALESCE(ssa.store_net_profit,0) AS store_net_profit,
    COALESCE(wsa.web_net_profit,0) AS web_net_profit,
    COALESCE(ssa.store_orders,0) AS store_orders,
    COALESCE(wsa.web_orders,0) AS web_orders
  FROM customer_info ci
  CROSS JOIN quarter_info qi
  LEFT JOIN store_sales_agg ssa ON ci.c_customer_sk = ssa.c_customer_sk
  LEFT JOIN web_sales_agg wsa ON ci.c_customer_sk = wsa.c_customer_sk
),
combined_returns AS (
  SELECT
    ci.c_customer_sk,
    ci.c_customer_id,
    ci.cust_name,
    qi.d_year,
    qi.d_quarter_seq,
    COALESCE(sra.store_net_loss,0) AS store_net_loss,
    COALESCE(wra.web_net_loss,0) AS web_net_loss
  FROM customer_info ci
  CROSS JOIN quarter_info qi
  LEFT JOIN store_returns_agg sra ON ci.c_customer_sk = sra.c_customer_sk
  LEFT JOIN web_returns_agg wra ON ci.c_customer_sk = wra.c_customer_sk
),
full_combined AS (
  SELECT
    COALESCE(cs.c_customer_sk, cr.c_customer_sk) AS c_customer_sk,
    COALESCE(cs.c_customer_id, cr.c_customer_id) AS c_customer_id,
    COALESCE(cs.cust_name, cr.cust_name) AS cust_name,
    COALESCE(cs.d_year, cr.d_year) AS d_year,
    COALESCE(cs.d_quarter_seq, cr.d_quarter_seq) AS d_quarter_seq,
    cs.store_net_profit,
    cs.web_net_profit,
    cr.store_net_loss,
    cr.web_net_loss,
    cs.store_orders,
    cs.web_orders,
    (cs.store_net_profit - cr.store_net_loss) AS net_profit_store,
    (cs.web_net_profit - cr.web_net_loss) AS net_profit_web,
    (cs.store_net_profit + cs.web_net_profit - cr.store_net_loss - cr.web_net_loss) AS total_net_profit,
    CASE 
      WHEN (cs.store_net_profit + cs.web_net_profit) > 0 THEN 'POSITIVE' 
      ELSE 'NON-POSITIVE' 
    END AS profit_category
  FROM combined_sales cs
  FULL OUTER JOIN combined_returns cr
    ON cs.c_customer_sk = cr.c_customer_sk
),
channel_profit AS (
  SELECT
    fc.c_customer_sk,
    fc.c_customer_id,
    fc.cust_name,
    fc.d_year,
    fc.d_quarter_seq,
    'STORE' AS channel,
    (fc.store_net_profit - fc.store_net_loss) AS channel_net_profit,
    fc.store_orders AS orders
  FROM full_combined fc
  UNION ALL
  SELECT
    fc.c_customer_sk,
    fc.c_customer_id,
    fc.cust_name,
    fc.d_year,
    fc.d_quarter_seq,
    'WEB' AS channel,
    (fc.web_net_profit - fc.web_net_loss) AS channel_net_profit,
    fc.web_orders AS orders
  FROM full_combined fc
),
ranked_channel AS (
  SELECT
    cp.*,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq, channel ORDER BY channel_net_profit DESC) AS channel_rank
  FROM channel_profit cp
  WHERE cp.channel_net_profit IS NOT NULL
),
top_channel_customers AS (
  SELECT *
  FROM ranked_channel
  WHERE channel_rank <= 5
    AND channel_net_profit > 0
)
SELECT
  t.c_customer_id,
  t.cust_name,
  t.d_year,
  t.d_quarter_seq,
  t.channel,
  t.channel_net_profit,
  t.channel_rank,
  CASE WHEN t.orders > 0 THEN t.channel_net_profit / t.orders END AS profit_per_order,
  'Rank_' || CAST(t.channel_rank AS VARCHAR) || '_' || t.channel AS rank_label,
  CASE WHEN t.channel_net_profit >= 20000 THEN true ELSE false END AS high_profit_flag
FROM top_channel_customers t
ORDER BY t.d_year, t.d_quarter_seq, t.channel, t.channel_rank
