WITH
store_items AS (
  SELECT DISTINCT ss_item_sk AS item_sk
  FROM store_sales
),
web_items AS (
  SELECT DISTINCT ws_item_sk AS item_sk
  FROM web_sales
),
catalog_items AS (
  SELECT DISTINCT cs_item_sk AS item_sk
  FROM catalog_sales
),
common_items AS (
  SELECT item_sk FROM store_items
  INTERSECT
  SELECT item_sk FROM web_items
  INTERSECT
  SELECT item_sk FROM catalog_items
),
sales_all AS (
  SELECT ss_item_sk AS item_sk,
         ss_sold_date_sk AS date_sk,
         ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT ws_item_sk,
         ws_sold_date_sk,
         ws_net_profit,
         'web' AS channel
  FROM web_sales
  UNION ALL
  SELECT cs_item_sk,
         cs_sold_date_sk,
         cs_net_profit,
         'catalog' AS channel
  FROM catalog_sales
),
sales_by_item_year AS (
  SELECT s.item_sk,
         d.d_year AS year,
         SUM(s.net_profit) AS total_net_profit,
         AVG(s.net_profit) AS avg_monthly_net_profit,
         COUNT(DISTINCT d.d_month_seq) AS months_sold
  FROM sales_all s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY s.item_sk, d.d_year
),
latest_inventory AS (
  SELECT inv_item_sk AS item_sk,
         inv_quantity_on_hand AS latest_quantity,
         inv_date_sk AS inv_date_sk
  FROM (
    SELECT inv_item_sk,
           inv_quantity_on_hand,
           inv_date_sk,
           ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
  ) t
  WHERE rn = 1
),
promo_info AS (
  SELECT p.p_item_sk AS item_sk,
         p.p_cost AS promo_cost,
         p.p_discount_active AS discount_active,
         p.p_promo_name AS promo_name
  FROM promotion p
  WHERE p.p_discount_active = 'Y'
),
returns_all AS (
  SELECT sr.sr_item_sk AS item_sk,
         sr.sr_returned_date_sk AS date_sk,
         sr.sr_return_quantity AS return_qty,
         sr.sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_item_sk,
         wr.wr_returned_date_sk,
         wr.wr_return_quantity,
         wr.wr_net_loss,
         'web' AS channel
  FROM web_returns wr
  UNION ALL
  SELECT cr.cr_item_sk,
         cr.cr_returned_date_sk,
         cr.cr_return_quantity,
         cr.cr_net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
),
returns_by_item_year AS (
  SELECT r.item_sk,
         d.d_year AS year,
         SUM(r.return_qty) AS total_return_qty,
         SUM(r.net_loss) AS total_return_loss
  FROM returns_all r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY r.item_sk, d.d_year
)
SELECT
  i.i_item_id,
  i.i_product_name,
  CONCAT(i.i_item_id, '-', i.i_product_name) AS full_item_code,
  i.i_brand,
  i.i_category,
  i.i_size,
  sbiy.year,
  sbiy.total_net_profit,
  sbiy.avg_monthly_net_profit,
  sbiy.months_sold,
  RANK() OVER (PARTITION BY sbiy.year ORDER BY sbiy.total_net_profit DESC) AS profit_rank,
  COALESCE(pi.promo_cost, 0) AS promo_cost,
  CASE WHEN pi.discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
  COALESCE(li.latest_quantity, 0) AS latest_inventory_qty,
  CASE WHEN COALESCE(li.latest_quantity, 0) < 100 THEN 'Low Stock' ELSE 'Sufficient Stock' END AS stock_status,
  COALESCE(rby.total_return_qty, 0) AS total_return_qty,
  COALESCE(rby.total_return_loss, 0) AS total_return_loss,
  (SELECT SUM(s2.net_profit)
   FROM sales_all s2
   JOIN date_dim d2 ON s2.date_sk = d2.d_date_sk
   WHERE s2.item_sk = i.i_item_sk
     AND d2.d_year = sbiy.year - 1) AS last_year_total_net_profit,
  CASE WHEN EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk)
        OR EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_item_sk = i.i_item_sk)
        OR EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = i.i_item_sk)
       THEN 'Yes' ELSE 'No' END AS any_return_flag
FROM sales_by_item_year sbiy
JOIN common_items ci ON sbiy.item_sk = ci.item_sk
JOIN item i ON sbiy.item_sk = i.i_item_sk
LEFT JOIN promo_info pi ON i.i_item_sk = pi.item_sk
LEFT JOIN latest_inventory li ON i.i_item_sk = li.item_sk
LEFT JOIN returns_by_item_year rby ON sbiy.item_sk = rby.item_sk AND sbiy.year = rby.year
WHERE sbiy.year = 1998
ORDER BY sbiy.total_net_profit DESC
LIMIT 50
