WITH store_sales_agg AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_profit) AS profit,
    SUM(ss.ss_quantity) AS quantity,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating = 'Good'
    AND cd.cd_gender = 'F'
    AND d.d_year = 2020
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_net_profit) AS profit,
    SUM(ws.ws_quantity) AS quantity,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating = 'Good'
    AND cd.cd_gender = 'F'
    AND d_sold.d_year = 2020
  GROUP BY i.i_category, d_sold.d_year, d_sold.d_month_seq
),
sales_combined AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
profit_by_category_month AS (
  SELECT
    i_category,
    d_year,
    d_month_seq,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity
  FROM sales_combined
  GROUP BY i_category, d_year, d_month_seq
),
inventory_agg AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2020
  GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
  p.i_category,
  p.d_year,
  p.d_month_seq,
  p.total_profit,
  p.total_quantity,
  i.avg_inventory_on_hand,
  ROUND(p.total_profit / NULLIF(i.avg_inventory_on_hand, 0), 2) AS profit_per_inventory,
  LAG(p.total_profit) OVER (PARTITION BY p.i_category ORDER BY p.d_month_seq) AS prev_month_profit,
  CASE
    WHEN LAG(p.total_profit) OVER (PARTITION BY p.i_category ORDER BY p.d_month_seq) IS NULL THEN NULL
    ELSE ROUND(
      (p.total_profit - LAG(p.total_profit) OVER (PARTITION BY p.i_category ORDER BY p.d_month_seq))
      / NULLIF(LAG(p.total_profit) OVER (PARTITION BY p.i_category ORDER BY p.d_month_seq), 0) * 100,
      2
    )
  END AS month_over_month_profit_pct
FROM profit_by_category_month p
LEFT JOIN inventory_agg i
  ON p.i_category = i.i_category
  AND p.d_year = i.d_year
  AND p.d_month_seq = i.d_month_seq
WHERE p.total_profit IS NOT NULL
ORDER BY p.total_profit DESC
LIMIT 10
