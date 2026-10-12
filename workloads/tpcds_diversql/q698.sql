WITH
  sales_agg AS (
    SELECT
      p.p_promo_id,
      ca.ca_state,
      hd.hd_income_band_sk,
      SUM(cs.cs_net_paid) AS total_paid,
      COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND ca.ca_county = 'Richland County'
      AND hd.hd_income_band_sk >= 10
    GROUP BY GROUPING SETS (
      (p.p_promo_id, ca.ca_state),
      (hd.hd_income_band_sk),
      ()
    )
  ),
  returns_agg AS (
    SELECT
      sr.sr_store_sk,
      hd.hd_dep_count,
      SUM(sr.sr_return_amt) AS total_return,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE hd.hd_dep_count >= 5
      AND sr.sr_return_amt > 0
      AND ca.ca_state = 'TX'
    GROUP BY GROUPING SETS (
      (sr.sr_store_sk),
      (hd.hd_dep_count),
      ()
    )
  ),
  promo_full AS (
    SELECT
      p.p_promo_id,
      COALESCE(cs.total_paid, 0) AS total_paid,
      COALESCE(cs.order_cnt, 0) AS order_cnt
    FROM promotion p
    FULL OUTER JOIN (
      SELECT
        cs_promo_sk,
        SUM(cs_net_paid) AS total_paid,
        COUNT(*) AS order_cnt
      FROM catalog_sales
      WHERE cs_quantity > 0
      GROUP BY cs_promo_sk
    ) cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE p.p_channel_catalog = 'N'
  ),
  common_hh AS (
    SELECT hd_demo_sk FROM catalog_sales
    JOIN household_demographics hd ON catalog_sales.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE catalog_sales.cs_quantity > 1
    INTERSECT
    SELECT hd_demo_sk FROM store_returns
    JOIN household_demographics hd2 ON store_returns.sr_hdemo_sk = hd2.hd_demo_sk
    WHERE store_returns.sr_return_quantity > 0
  ),
  excluded_hh AS (
    SELECT hd_demo_sk FROM household_demographics
    WHERE hd_dep_count = 0
    EXCEPT
    SELECT hd_demo_sk FROM common_hh
  )
SELECT
  sa.p_promo_id,
  sa.ca_state,
  sa.hd_income_band_sk,
  sa.total_paid,
  ra.sr_store_sk,
  ra.total_return,
  CASE WHEN EXISTS (SELECT 1 FROM common_hh ch WHERE ch.hd_demo_sk = sa.hd_income_band_sk) THEN 1 ELSE 0 END AS is_common_household,
  CASE WHEN EXISTS (SELECT 1 FROM excluded_hh ex WHERE ex.hd_demo_sk = ra.sr_store_sk) THEN 1 ELSE 0 END AS is_excluded_store
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra ON TRUE
WHERE sa.total_paid > 500
  AND ra.total_return > 0
  AND (sa.hd_income_band_sk IS NOT NULL OR ra.sr_store_sk IS NOT NULL)
ORDER BY sa.total_paid DESC
LIMIT 100
