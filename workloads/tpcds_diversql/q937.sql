WITH
  sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  sampled_catalog_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  date_dim_ss AS (
    SELECT *
    FROM date_dim
  ),
  date_dim_full AS (
    SELECT *
    FROM date_dim
  ),
  intersect_customers AS (
    SELECT ss_customer_sk
    FROM sampled_store_sales
    INTERSECT
    SELECT cs_bill_customer_sk
    FROM sampled_catalog_sales
  )
SELECT
  d_ss.d_year,
  i.i_category,
  cd.cd_gender,
  hd.hd_buy_potential,
  SUM(ss.ss_ext_sales_price)        AS total_store_sales,
  SUM(cs.cs_ext_sales_price)         AS total_catalog_sales,
  SUM(inv.inv_quantity_on_hand)      AS total_inventory_quantity,
  MIN(ib.ib_lower_bound)            AS income_lower_bound,
  MAX(ib.ib_upper_bound)            AS income_upper_bound
FROM sampled_store_sales ss
JOIN date_dim_ss d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd_inc
  ON c.c_current_hdemo_sk = hd_inc.hd_demo_sk
JOIN income_band ib
  ON hd_inc.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN sampled_catalog_sales cs
  ON cs.cs_bill_customer_sk = ss.ss_customer_sk
     AND cs.cs_item_sk = ss.ss_item_sk
FULL OUTER JOIN date_dim_full d_full
  ON d_full.d_date_sk = ss.ss_sold_date_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = ss.ss_item_sk
     AND inv.inv_date_sk = ss.ss_sold_date_sk
WHERE ss.ss_customer_sk IN (SELECT ss_customer_sk FROM intersect_customers)
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY CUBE (d_ss.d_year, i.i_category, cd.cd_gender, hd.hd_buy_potential)
ORDER BY total_store_sales DESC
OFFSET 0
LIMIT 100
