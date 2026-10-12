WITH combined_sales AS (
  SELECT
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_bill_cdemo_sk AS demo_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
    cs.cs_net_profit AS net_profit,
    'catalog' AS channel
  FROM catalog_sales cs
  WHERE cs.cs_net_paid_inc_tax > 500
  UNION ALL
  SELECT
    ws.ws_sold_date_sk AS sold_date_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_bill_cdemo_sk AS demo_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
    ws.ws_net_profit AS net_profit,
    'web' AS channel
  FROM web_sales ws
  WHERE ws.ws_net_paid_inc_tax > 500
),
inventory_agg AS (
  SELECT inv_item_sk, AVG(inv_quantity_on_hand) AS avg_qty_on_hand
  FROM inventory
  GROUP BY inv_item_sk
)
SELECT
  i.i_category AS category,
  cd.cd_gender AS gender,
  cd.cd_education_status AS education_status,
  SUM(s.quantity) AS total_quantity,
  SUM(s.net_paid_inc_tax) AS total_sales,
  SUM(s.net_profit) AS total_profit,
  AVG(ia.avg_qty_on_hand) AS avg_inventory_on_hand,
  ROUND(SUM(s.net_profit) / NULLIF(AVG(ia.avg_qty_on_hand), 0), 2) AS profit_per_inventory,
  RANK() OVER (ORDER BY SUM(s.net_profit) DESC) AS profit_rank
FROM combined_sales s
JOIN item i ON s.item_sk = i.i_item_sk
JOIN customer_demographics cd ON s.demo_sk = cd.cd_demo_sk
LEFT JOIN inventory_agg ia ON i.i_item_sk = ia.inv_item_sk
WHERE i.i_category IS NOT NULL
GROUP BY
  i.i_category,
  cd.cd_gender,
  cd.cd_education_status
HAVING SUM(s.net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
