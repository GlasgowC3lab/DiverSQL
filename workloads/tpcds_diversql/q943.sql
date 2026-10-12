WITH
  full_cc_date AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      d.d_year
    FROM call_center cc
    FULL OUTER JOIN date_dim d
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_state IN ('CA', 'NY')
      AND (d.d_year BETWEEN 2000 AND 2002 OR d.d_year IS NULL)
  ),
  unioned_sales AS (
    SELECT
      d.d_year AS year,
      cc.cc_call_center_sk,
      cc.cc_name AS call_center_name,
      p.p_promo_name AS promo_name,
      cs.cs_ext_sales_price AS sales,
      cs.cs_net_profit AS profit,
      cust.c_customer_id AS customer_id,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_date_sk = cs.cs_sold_date_sk
      ) AS inventory_on_date,
      p.p_discount_active AS discount_active
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND p.p_channel_email = 'Y'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1

    UNION DISTINCT

    SELECT
      d.d_year AS year,
      cc.cc_call_center_sk,
      cc.cc_name AS call_center_name,
      p.p_promo_name AS promo_name,
      cs.cs_ext_sales_price AS sales,
      cs.cs_net_profit AS profit,
      cust.c_customer_id AS customer_id,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_date_sk = cs.cs_sold_date_sk
      ) AS inventory_on_date,
      p.p_discount_active AS discount_active
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND cc.cc_state = 'NY'
      AND p.p_channel_tv = 'Y'
      AND p.p_discount_active = 'N'
      AND cs.cs_quantity > 5
  )
SELECT
  COALESCE(us.year, fcd.d_year)            AS year,
  COALESCE(us.call_center_name, fcd.cc_name) AS call_center_name,
  COALESCE(us.promo_name, 'No Promo')     AS promo_name,
  SUM(us.sales)                           AS total_sales,
  AVG(us.profit)                          AS avg_profit,
  COUNT(DISTINCT us.customer_id)          AS unique_customers,
  SUM(CASE WHEN us.discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_count,
  MAX(us.inventory_on_date)               AS max_inventory,
  CASE
    WHEN COUNT(*) FILTER (WHERE us.discount_active = 'Y') > 10 THEN 'High Discount'
    ELSE 'Low Discount'
  END                                      AS discount_category
FROM unioned_sales us
FULL OUTER JOIN full_cc_date fcd
  ON us.cc_call_center_sk = fcd.cc_call_center_sk
 AND us.year = fcd.d_year
GROUP BY
  COALESCE(us.year, fcd.d_year),
  COALESCE(us.call_center_name, fcd.cc_name),
  COALESCE(us.promo_name, 'No Promo')
ORDER BY total_sales DESC
LIMIT 100
