WITH store_sales_agg AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    AVG(ss.ss_ext_discount_amt) AS store_avg_discount,
    COUNT(DISTINCT ss.ss_store_sk) AS distinct_store_cnt
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE s.s_state = 'CA'
  GROUP BY ss.ss_customer_sk
),
catalog_sales_agg AS (
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    AVG(cs.cs_ext_discount_amt) AS catalog_avg_discount,
    COUNT(DISTINCT cc.cc_call_center_sk) AS distinct_call_center_cnt
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_state = 'CA'
  GROUP BY cs.cs_bill_customer_sk
),
web_returns_agg AS (
  SELECT
    wr.wr_refunded_customer_sk AS customer_sk,
    SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE ca.ca_state = 'CA'
  GROUP BY wr.wr_refunded_customer_sk
),
customer_sales AS (
  SELECT
    c.c_customer_sk,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) - COALESCE(wr.total_return_loss, 0) AS total_net_profit,
    COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) AS total_sales_amount,
    CASE
      WHEN COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) = 0 THEN 0
      ELSE (COALESCE(ss.store_avg_discount, 0) * COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_avg_discount, 0) * COALESCE(cs.catalog_sales_amount, 0)) /
           (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0))
    END AS weighted_avg_discount,
    COALESCE(ss.distinct_store_cnt, 0) + COALESCE(cs.distinct_call_center_cnt, 0) AS distinct_channels_cnt
  FROM customer c
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN store_sales_agg ss
    ON ss.customer_sk = c.c_customer_sk
  LEFT JOIN catalog_sales_agg cs
    ON cs.customer_sk = c.c_customer_sk
  LEFT JOIN web_returns_agg wr
    ON wr.customer_sk = c.c_customer_sk
  WHERE ca.ca_state = 'CA'
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cust.total_net_profit,
  cust.total_sales_amount,
  cust.weighted_avg_discount,
  cust.distinct_channels_cnt,
  RANK() OVER (ORDER BY cust.total_net_profit DESC) AS profit_rank
FROM customer_sales cust
JOIN customer c
  ON cust.c_customer_sk = c.c_customer_sk
ORDER BY profit_rank
LIMIT 10
