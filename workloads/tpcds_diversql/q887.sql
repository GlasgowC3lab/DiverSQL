WITH
  page_filtered AS (
    SELECT
      cp_catalog_page_sk,
      cp_catalog_page_id,
      cp_type,
      cp_description
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)\\bfamily\\b')
      AND cp_type LIKE 'A%'
  ),
  promo_filtered AS (
    SELECT
      p_promo_sk,
      p_promo_name
    FROM promotion
    WHERE regexp_like(p_channel_details, '(?i)old|ancient')
      AND p_promo_name LIKE '%Discount%'
  ),
  order_set_a AS (
    SELECT DISTINCT cs.cs_order_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)\\bkill\\b')
  ),
  order_set_b AS (
    SELECT DISTINCT cs.cs_order_number
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_channel_details, '(?i)\\bfamily\\b')
  ),
  order_diff AS (
    SELECT cs_order_number FROM order_set_a
    EXCEPT
    SELECT cs_order_number FROM order_set_b
  ),
  sales_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_catalog_page_sk,
      cs.cs_promo_sk,
      cs.cs_ship_mode_sk,
      cs.cs_net_paid,
      cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > (
      SELECT avg(cs2.cs_net_paid)
      FROM catalog_sales cs2
    )
  )
SELECT
  pf.cp_catalog_page_id,
  pf.cp_type,
  sm.sm_carrier,
  pf2.p_promo_name,
  sj.cs_order_number,
  sj.cs_net_paid,
  sj.cs_quantity,
  regexp_extract(pf.cp_description, '(\\w+)\\s+kill', 1) AS keyword_before_kill,
  (
    SELECT sum(cs3.cs_quantity)
    FROM catalog_sales cs3
    WHERE cs3.cs_catalog_page_sk = pf.cp_catalog_page_sk
  ) AS total_quantity_for_page,
  CASE
    WHEN sj.cs_net_paid > (
      SELECT max(cs4.cs_net_paid)
      FROM catalog_sales cs4
    ) THEN 'Top'
    ELSE 'Other'
  END AS profit_category
FROM page_filtered pf
JOIN sales_join sj ON pf.cp_catalog_page_sk = sj.cs_catalog_page_sk
JOIN ship_mode sm ON sj.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN promo_filtered pf2 ON sj.cs_promo_sk = pf2.p_promo_sk
WHERE sj.cs_order_number IN (SELECT cs_order_number FROM order_diff)
ORDER BY sj.cs_net_paid DESC
OFFSET 20
LIMIT 100
