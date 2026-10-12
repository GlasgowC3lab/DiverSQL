WITH
  -- 10% random sample of web_sales for the year 2001
  sales_sample AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_order_number,
      ws.ws_bill_cdemo_sk
    FROM web_sales ws TABLESAMPLE BERNOULLI (10)
    WHERE ws.ws_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
  ),
  -- Items that have an active promotion
  promo_items AS (
    SELECT p.p_item_sk AS item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
  ),
  -- Items that are promoted but did NOT appear in the sampled sales (EXCEPT)
  items_without_sales AS (
    SELECT pi.item_sk
    FROM promo_items pi
    EXCEPT
    SELECT ss.ws_item_sk
    FROM sales_sample ss
  ),
  -- Small dimension: every combination of a year and a discount flag (CROSS JOIN)
  year_flag AS (
    SELECT y.year, f.flag
    FROM (VALUES 2000, 2001, 2002) AS y (year)
    CROSS JOIN (VALUES 'Y', 'N') AS f (flag)
  )
SELECT
  i.i_item_id,
  d.d_year,
  COUNT(DISTINCT ss.ws_order_number) AS orders,
  SUM(ss.ws_quantity) AS total_qty,
  SUM(ss.ws_ext_sales_price) AS revenue,
  CASE
    WHEN cd.cd_purchase_estimate >= 4000 THEN 'HIGH'
    ELSE 'LOW'
  END AS purchase_category,
  CONCAT(i.i_product_name, ' - Mgr', CAST(i.i_manager_id AS VARCHAR)) AS product_label,
  regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number,
  yf.year,
  yf.flag
FROM sales_sample ss
JOIN date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN year_flag yf ON d.d_year = yf.year
WHERE i.i_formulation LIKE '%olive%'
  AND regexp_like(i.i_formulation, '^\\d+')
  AND cd.cd_marital_status LIKE 'M%'
  -- Exclude items that are promoted but have no sales in the sampled set
  AND i.i_item_sk NOT IN (SELECT item_sk FROM items_without_sales)
GROUP BY
  i.i_item_id,
  d.d_year,
  cd.cd_purchase_estimate,
  i.i_product_name,
  i.i_manager_id,
  i.i_formulation,
  yf.year,
  yf.flag
HAVING SUM(ss.ws_ext_sales_price) > 1000
ORDER BY revenue DESC
LIMIT 100
