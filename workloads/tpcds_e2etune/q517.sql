WITH daily_sales AS (
  SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month_seq,
    w.w_state AS w_state,
    w.w_city AS w_city,
    SUM(cs.cs_net_profit) AS daily_net_profit,
    SUM(cs.cs_quantity) AS daily_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS daily_orders,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year BETWEEN 2000 AND 2002
    AND cs.cs_quantity > 10
    AND w.w_state IN ('CA', 'TX', 'NY')
  GROUP BY d_sold.d_year, d_sold.d_month_seq, w.w_state, w.w_city
),
monthly_sales AS (
  SELECT
    year,
    month_seq,
    w_state,
    w_city,
    SUM(daily_net_profit) AS month_net_profit,
    SUM(daily_quantity) AS month_quantity,
    AVG(avg_discount) AS avg_month_discount,
    SUM(daily_orders) AS month_orders,
    SUM(distinct_web_pages) AS month_distinct_web_pages
  FROM daily_sales
  GROUP BY year, month_seq, w_state, w_city
  HAVING SUM(daily_net_profit) > 10000
)
SELECT
  year,
  month_seq,
  w_state,
  w_city,
  month_net_profit,
  month_quantity,
  avg_month_discount,
  month_orders,
  month_distinct_web_pages,
  RANK() OVER (PARTITION BY year, month_seq ORDER BY month_net_profit DESC) AS profit_rank
FROM monthly_sales
ORDER BY year, month_seq, profit_rank
LIMIT 100
