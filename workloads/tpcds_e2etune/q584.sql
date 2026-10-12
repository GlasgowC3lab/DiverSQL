WITH sales_by_warehouse_month AS (
  SELECT
    w.w_warehouse_name,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE d_sold.d_year = 2001
    AND cs.cs_ext_discount_amt > 500
    AND t.t_shift = 'Morning'
  GROUP BY w.w_warehouse_name, d_sold.d_year, d_sold.d_month_seq
),

inventory_by_warehouse_month AS (
  SELECT
    w.w_warehouse_name,
    d_inv.d_year,
    d_inv.d_month_seq AS month_seq,
    SUM(i.inv_quantity_on_hand) AS total_inventory
  FROM inventory i
  JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
  JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d_inv.d_year = 2001
  GROUP BY w.w_warehouse_name, d_inv.d_year, d_inv.d_month_seq
),

web_pages_by_month AS (
  SELECT
    d_wp.d_year,
    d_wp.d_month_seq AS month_seq,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages
  FROM web_page wp
  JOIN date_dim d_wp
    ON wp.wp_creation_date_sk = d_wp.d_date_sk
  WHERE d_wp.d_year = 2001
  GROUP BY d_wp.d_year, d_wp.d_month_seq
)

SELECT
  s.w_warehouse_name,
  s.d_year,
  s.month_seq,
  s.total_net_profit,
  s.avg_discount,
  s.orders_cnt,
  i.total_inventory,
  wp.distinct_pages,
  RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_by_warehouse_month s
LEFT JOIN inventory_by_warehouse_month i
  ON s.w_warehouse_name = i.w_warehouse_name
  AND s.d_year = i.d_year
  AND s.month_seq = i.month_seq
LEFT JOIN web_pages_by_month wp
  ON s.d_year = wp.d_year
  AND s.month_seq = wp.month_seq
ORDER BY s.d_year, s.month_seq, profit_rank
LIMIT 200
