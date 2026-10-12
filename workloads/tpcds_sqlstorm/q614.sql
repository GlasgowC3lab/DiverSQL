WITH catalog_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS revenue,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS revenue,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS revenue,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_order_number) AS orders
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined AS (
 SELECT * FROM catalog_agg
 UNION ALL
 SELECT * FROM store_agg
 UNION ALL
 SELECT * FROM web_agg
),
aggregated AS (
 SELECT year, month, category,
        SUM(revenue) AS total_revenue,
        SUM(quantity) AS total_quantity,
        SUM(orders) AS total_orders
 FROM combined
 GROUP BY year, month, category
),
ranked AS (
 SELECT year, month, category, total_revenue, total_quantity, total_orders,
        RANK() OVER (PARTITION BY year, month ORDER BY total_revenue DESC) AS revenue_rank,
        approx_percentile(total_revenue, 0.5) OVER (PARTITION BY year, month) AS median_revenue
 FROM aggregated
)
SELECT year, month, category, total_revenue, total_quantity, total_orders, revenue_rank, median_revenue
FROM ranked
WHERE revenue_rank <= 10
ORDER BY year, month, revenue_rank
