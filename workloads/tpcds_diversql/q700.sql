WITH sales_data AS (
   SELECT
       ws.ws_item_sk,
       ws.ws_sold_date_sk,
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_promo_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
),
promo_match AS (
   SELECT
       p.p_promo_sk,
       1 AS is_clearance
   FROM promotion p
   WHERE regexp_like(p.p_promo_name, '(?i)clearance')
),
aggregated AS (
   SELECT
       i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       d.d_year,
       SUM(sd.ws_ext_sales_price) AS total_sales,
       COUNT(DISTINCT sd.ws_order_number) AS orders_cnt,
       MAX(COALESCE(pm.is_clearance, 0)) AS has_clearance_promo,
       SUM(CASE WHEN i.i_product_name LIKE '%Widget%' THEN sd.ws_quantity ELSE 0 END) AS widget_quantity
   FROM sales_data sd
   JOIN item i ON sd.ws_item_sk = i.i_item_sk
   JOIN date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN promo_match pm ON sd.ws_promo_sk = pm.p_promo_sk
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year
)
SELECT
   a.i_item_id,
   CONCAT('Item: ', a.i_item_id) AS item_label,
   a.i_product_name,
   a.d_year,
   a.total_sales,
   a.orders_cnt,
   CASE WHEN a.has_clearance_promo = 1 THEN 'Clearance' ELSE 'Regular' END AS promo_type,
   a.widget_quantity,
   (SELECT SUM(wr.wr_return_amt)
    FROM web_returns wr
    WHERE wr.wr_item_sk = a.i_item_sk) AS total_return_amount,
   (SELECT r.r_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_item_sk = a.i_item_sk
      AND regexp_extract(r.r_reason_desc, '^\\w+') = 'Did'
    ORDER BY wr.wr_return_amt DESC
    LIMIT 1) AS top_return_reason,
   dt.discount_rate,
   CASE
       WHEN a.total_sales * (1 - dt.discount_rate) > 10000 THEN 'High'
       ELSE 'Medium'
   END AS sales_category
FROM aggregated a
CROSS JOIN (SELECT 0.0 AS discount_rate UNION ALL SELECT 0.10 UNION ALL SELECT 0.20) dt
WHERE a.total_sales > 0
ORDER BY a.total_sales DESC
LIMIT 100
