WITH sales_union AS (
  SELECT
    d.d_year AS d_year,
    ca.ca_state AS ca_state,
    i.i_category AS i_category,
    cs.cs_net_profit AS net_profit,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS sales_amount,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2000
    AND i.i_category = 'Electronics'
    AND hd.hd_income_band_sk >= 10
    AND ca.ca_state = 'CA'
  UNION ALL
  SELECT
    d2.d_year AS d_year,
    ca2.ca_state AS ca_state,
    i2.i_category AS i_category,
    ss.ss_net_profit AS net_profit,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS sales_amount,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
  JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
  JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
  WHERE d2.d_year = 2000
    AND i2.i_category = 'Electronics'
    AND hd2.hd_income_band_sk >= 10
    AND ca2.ca_state = 'CA'
),
agg_sales AS (
  SELECT
    d_year,
    ca_state,
    i_category,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS txn_cnt
  FROM sales_union
  GROUP BY d_year, ca_state, i_category
  HAVING SUM(quantity) > 100
)
SELECT
  d_year,
  ca_state,
  i_category,
  total_net_profit,
  total_quantity,
  txn_cnt,
  LAG(total_net_profit) OVER (PARTITION BY ca_state ORDER BY total_net_profit DESC) AS prev_profit,
  SUM(total_net_profit) OVER (PARTITION BY ca_state ORDER BY total_net_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_profit
FROM agg_sales
WHERE total_net_profit > (
  SELECT AVG(total_net_profit) FROM agg_sales
)
ORDER BY total_net_profit DESC
LIMIT 100
