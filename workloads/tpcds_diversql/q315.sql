WITH sales AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_sold_date_sk,
    d.d_date,
    d.d_year,
    ss.ss_quantity,
    ss.ss_net_paid,
    p.p_promo_name,
    p.p_discount_active
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND ss.ss_quantity > 5
    AND p.p_discount_active = 'Y'
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND ss.ss_net_paid > 100
    AND ss.ss_item_sk IN (101425, 101438, 101420)
    AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
inventory_cte AS (
  SELECT
    i.inv_item_sk,
    i.inv_warehouse_sk,
    i.inv_quantity_on_hand,
    d.d_date AS inv_date,
    d.d_year AS inv_year
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  WHERE i.inv_quantity_on_hand > 0
    AND d.d_year = 2001
    AND i.inv_warehouse_sk IN (15, 16, 17)
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
returns_cte AS (
  SELECT
    cr.cr_item_sk,
    cr.cr_store_credit,
    cr.cr_return_amount,
    d.d_date AS return_date,
    d.d_year AS return_year
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE cr.cr_store_credit > 0
    AND d.d_year = 2001
    AND cr.cr_return_amount > 0
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
items_intersection AS (
  SELECT ss_item_sk AS item_sk FROM sales
  INTERSECT
  SELECT inv_item_sk FROM inventory_cte
)
SELECT
  s.ss_item_sk,
  s.ss_store_sk,
  s.d_date,
  s.d_year,
  s.ss_quantity,
  s.ss_net_paid,
  i.inv_quantity_on_hand,
  r.cr_store_credit,
  CASE
    WHEN r.cr_store_credit > 50 THEN 'HIGH_CREDIT'
    ELSE 'LOW_CREDIT'
  END AS credit_category,
  ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_net_paid DESC) AS sales_rank,
  SUM(s.ss_net_paid) OVER (
    PARTITION BY s.ss_item_sk
    ORDER BY s.d_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_3day_sales
FROM sales s
JOIN inventory_cte i ON s.ss_item_sk = i.inv_item_sk
JOIN returns_cte r ON s.ss_item_sk = r.cr_item_sk
WHERE s.ss_item_sk IN (SELECT item_sk FROM items_intersection)
  AND EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = s.ss_item_sk
      AND cr2.cr_return_amount > 0
  )
ORDER BY s.d_year, s.d_date, sales_rank
LIMIT 100
