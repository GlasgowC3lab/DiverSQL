WITH aggregated AS (
   SELECT
       i.i_brand_id,
       i.i_brand,
       i.i_product_name,
       i.i_color,
       SUM(ss.ss_net_profit) AS total_net_profit,
       SUM(ss.ss_quantity) AS total_quantity,
       AVG(ss.ss_sales_price) AS avg_sales_price
   FROM tpcds.store_sales ss
   JOIN tpcds.item i
     ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_product_name LIKE '%ought%'
     AND i.i_color LIKE 'p%'
     AND regexp_like(i.i_product_name, '[aeiou]{2}')
   GROUP BY i.i_brand_id, i.i_brand, i.i_product_name, i.i_color
),
ranked AS (
   SELECT
       i_brand_id,
       i_brand,
       i_product_name,
       i_color,
       total_net_profit,
       total_quantity,
       avg_sales_price,
       concat(i_brand, '-', i_product_name) AS brand_product,
       row_number() OVER (PARTITION BY i_brand_id ORDER BY total_net_profit DESC) AS rn
   FROM aggregated
)
SELECT
   i_brand_id AS brand_id,
   i_brand AS brand,
   i_product_name AS product_name,
   i_color AS color,
   total_net_profit,
   total_quantity,
   avg_sales_price,
   brand_product
FROM ranked
WHERE rn <= 3
ORDER BY brand_id, rn
LIMIT 100
