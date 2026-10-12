WITH sales AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_id,
    p.p_promo_name,
    d.d_year,
    d.d_qoy AS promo_quarter,
    cs.cs_item_sk AS item_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_ext_sales_price AS sales_price
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
web AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_id,
    p.p_promo_name,
    d.d_year,
    d.d_qoy AS promo_quarter,
    ws.ws_item_sk AS item_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_ext_sales_price AS sales_price
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
sales_combined AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM web
),
inventory_monthly AS (
  SELECT
    i.inv_item_sk AS item_sk,
    d.d_year,
    d.d_qoy AS promo_quarter,
    AVG(i.inv_quantity_on_hand) AS avg_inventory
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  GROUP BY i.inv_item_sk, d.d_year, d.d_qoy
),
promo_sales AS (
  SELECT
    sc.p_promo_id,
    sc.p_promo_name,
    sc.d_year AS promo_year,
    sc.promo_quarter,
    SUM(sc.net_profit) AS total_net_profit,
    SUM(sc.discount_amt) AS total_discount,
    SUM(sc.quantity) AS total_quantity,
    SUM(sc.sales_price) AS total_sales_price,
    AVG(im.avg_inventory) AS avg_inventory
  FROM sales_combined sc
  LEFT JOIN inventory_monthly im
    ON sc.item_sk = im.item_sk
    AND sc.d_year = im.d_year
    AND sc.promo_quarter = im.promo_quarter
  GROUP BY sc.p_promo_id, sc.p_promo_name, sc.d_year, sc.promo_quarter
)
SELECT
  ps.p_promo_id,
  ps.p_promo_name,
  ps.promo_year,
  ps.promo_quarter,
  ps.total_net_profit,
  ps.total_discount,
  ps.total_quantity,
  ps.total_sales_price,
  ps.avg_inventory,
  (ps.total_quantity / NULLIF(ps.avg_inventory, 0)) AS inventory_turnover,
  RANK() OVER (PARTITION BY ps.promo_year, ps.promo_quarter ORDER BY ps.total_net_profit DESC) AS promo_rank
FROM promo_sales ps
ORDER BY ps.promo_year, ps.promo_quarter, promo_rank
LIMIT 50
