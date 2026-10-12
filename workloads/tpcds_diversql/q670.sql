WITH sales_agg AS (
   SELECT
       i.i_brand,
       i.i_category,
       d_sold.d_year,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_ext_sales_price) AS avg_sales,
       COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
       SUM(CASE WHEN ws.ws_ext_discount_amt > 50 THEN ws.ws_ext_discount_amt ELSE 0 END) AS high_discount_sum
   FROM web_sales ws
   JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE d_sold.d_year = 2001
     AND t_sold.t_hour BETWEEN 9 AND 17
     AND i.i_brand_id IN (1, 2, 3)
     AND wsite.web_state = 'CA'
     AND wp.wp_type = 'content'
     AND EXISTS (
         SELECT 1 FROM web_page wp2
         WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
           AND wp2.wp_char_count > 1000
     )
   GROUP BY i.i_brand, i.i_category, d_sold.d_year
),

inventory_latest AS (
   SELECT
       i.i_brand,
       i.i_category,
       d_inv.d_year,
       SUM(inv.inv_quantity_on_hand) AS total_inventory
   FROM inventory inv
   JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE d_inv.d_year BETWEEN 2000 AND 2002
     AND inv.inv_quantity_on_hand > 0
     AND i.i_color = 'red'
   GROUP BY i.i_brand, i.i_category, d_inv.d_year
),

returns_agg AS (
   SELECT
       i.i_brand,
       i.i_category,
       d_ret.d_year,
       SUM(sr.sr_return_amt) AS total_returns,
       COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
   JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d_ret.d_year = 2001
     AND t_ret.t_hour BETWEEN 9 AND 17
     AND sr.sr_return_tax > 20
     AND i.i_size = 'M'
   GROUP BY i.i_brand, i.i_category, d_ret.d_year
),

combined AS (
   SELECT
       s.i_brand,
       s.i_category,
       s.d_year,
       s.total_sales,
       s.avg_sales,
       s.orders_cnt,
       s.high_discount_sum,
       COALESCE(inv.total_inventory, 0) AS total_inventory,
       COALESCE(r.total_returns, 0) AS total_returns,
       COALESCE(r.return_cnt, 0) AS return_cnt,
       CASE
           WHEN s.total_sales > 100000 THEN 'HIGH'
           WHEN s.total_sales > 50000  THEN 'MEDIUM'
           ELSE 'LOW'
       END AS sales_level
   FROM sales_agg s
   LEFT JOIN inventory_latest inv
     ON s.i_brand = inv.i_brand
    AND s.i_category = inv.i_category
    AND s.d_year = inv.d_year
   LEFT JOIN returns_agg r
     ON s.i_brand = r.i_brand
    AND s.i_category = r.i_category
    AND s.d_year = r.d_year
),

ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS rn
   FROM combined
)
SELECT
   i_brand,
   i_category,
   d_year,
   total_sales,
   avg_sales,
   total_inventory,
   total_returns,
   sales_level
FROM ranked
WHERE rn <= 5
INTERSECT
SELECT
   i_brand,
   i_category,
   d_year,
   total_sales,
   avg_sales,
   total_inventory,
   total_returns,
   sales_level
FROM ranked
WHERE sales_level = 'HIGH'
ORDER BY total_sales DESC
LIMIT 100
