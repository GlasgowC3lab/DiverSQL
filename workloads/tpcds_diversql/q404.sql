WITH catalog_items AS (
  SELECT cs.cs_item_sk AS item_sk,
         SUM(cs.cs_ext_sales_price) AS total_cat_sales,
         SUM(cs.cs_net_profit) AS total_cat_profit,
         MAX(p.p_promo_name) AS any_promo_name
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND regexp_like(p.p_promo_name, '(?i)sale')
  GROUP BY cs.cs_item_sk
),
store_items AS (
  SELECT ss.ss_item_sk AS item_sk,
         SUM(ss.ss_ext_sales_price) AS total_store_sales,
         SUM(ss.ss_net_profit) AS total_store_profit,
         MAX(s.s_store_name) AS any_store_name
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_store_name LIKE '%Mall%'
  GROUP BY ss.ss_item_sk
),
item_filtered AS (
  SELECT i.i_item_sk,
         i.i_item_desc,
         i.i_brand,
         i.i_category,
         CONCAT(i.i_item_desc, ' - ', i.i_brand) AS full_desc
  FROM item i
  WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
    AND substring(i.i_item_desc, 1, 5) = 'Brand'
)
SELECT
  i.i_item_sk,
  i.full_desc,
  i.i_category,
  ci.total_cat_sales,
  si.total_store_sales,
  CASE
    WHEN ci.total_cat_profit > si.total_store_profit THEN 'Catalog higher'
    WHEN ci.total_cat_profit < si.total_store_profit THEN 'Store higher'
    ELSE 'Equal'
  END AS profit_comparison,
  (
    SELECT AVG(cs.cs_ext_sales_price)
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_date = DATE '2001-01-01'
  ) AS avg_sales_price_2001_01_01
FROM item_filtered i
JOIN catalog_items ci ON i.i_item_sk = ci.item_sk
JOIN store_items si ON i.i_item_sk = si.item_sk
WHERE i.i_item_sk IN (
      SELECT item_sk FROM catalog_items
      INTERSECT
      SELECT item_sk FROM store_items
    )
ORDER BY ci.total_cat_sales DESC
LIMIT 100
