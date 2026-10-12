WITH
sales_by_date AS (
  SELECT
    ss.ss_store_sk,
    s.s_store_name,
    d.d_date,
    d.d_year,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_ext_discount_amt) FILTER (WHERE ss.ss_coupon_amt IS NOT NULL AND ss.ss_coupon_amt > 0) AS total_coupon_discount,
    CASE
      WHEN SUM(ss.ss_quantity) > 100 THEN 'HIGH'
      WHEN SUM(ss.ss_quantity) BETWEEN 50 AND 100 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS volume_category
  FROM store_sales ss
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY GROUPING SETS ((ss.ss_store_sk, s.s_store_name, d.d_date, d.d_year), (ss.ss_store_sk, s.s_store_name, d.d_year))
),
returns_by_date AS (
  SELECT
    sr.sr_store_sk,
    s.s_store_name,
    d.d_date,
    d.d_year,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY GROUPING SETS ((sr.sr_store_sk, s.s_store_name, d.d_date, d.d_year), (sr.sr_store_sk, s.s_store_name, d.d_year))
),
combined_sales_returns AS (
  SELECT
    COALESCE(sales.ss_store_sk, ret.sr_store_sk) AS store_sk,
    COALESCE(sales.s_store_name, ret.s_store_name) AS store_name,
    COALESCE(sales.d_date, ret.d_date) AS the_date,
    COALESCE(sales.d_year, ret.d_year) AS the_year,
    COALESCE(sales.total_net_paid, 0) - COALESCE(ret.total_net_loss, 0) AS net_margin,
    COALESCE(sales.sales_cnt, 0) AS sales_cnt,
    COALESCE(ret.return_cnt, 0) AS return_cnt,
    COALESCE(sales.volume_category, 'UNKNOWN') AS volume_category,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(sales.ss_store_sk, ret.sr_store_sk) ORDER BY COALESCE(sales.d_date, ret.d_date) DESC) AS rn,
    CASE
      WHEN COALESCE(sales.total_net_paid, 0) = 0 THEN NULL
      ELSE CAST(COALESCE(sales.total_profit, 0) / COALESCE(sales.total_net_paid, 1) AS DOUBLE)
    END AS profit_ratio,
    CONCAT(COALESCE(sales.volume_category, 'UNKNOWN'), '-', CAST(COALESCE(ret.return_cnt, 0) AS VARCHAR)) AS vol_return_desc,
    CASE
      WHEN COALESCE(sales.total_net_paid, 0) > 1000 THEN 'HIGH_SPEND'
      WHEN COALESCE(sales.total_net_paid, 0) BETWEEN 500 AND 1000 THEN 'MEDIUM_SPEND'
      ELSE 'LOW_SPEND'
    END AS spend_category,
    EXISTS (
      SELECT 1
      FROM catalog_sales cs
      JOIN date_dim cd ON cs.cs_sold_date_sk = cd.d_date_sk
      WHERE cd.d_date = COALESCE(sales.d_date, ret.d_date)
        AND cs.cs_item_sk IS NOT NULL
    ) AS has_catalog_sales
  FROM sales_by_date sales
  FULL OUTER JOIN returns_by_date ret
    ON sales.ss_store_sk = ret.sr_store_sk
    AND sales.d_date = ret.d_date
),
final_metrics AS (
  SELECT
    c.*,
    (SELECT AVG(s2.total_profit)
     FROM sales_by_date s2
     WHERE s2.ss_store_sk = c.store_sk
       AND s2.d_date BETWEEN date_add('day', -30, c.the_date) AND c.the_date) AS avg_profit_last_30d,
    (SELECT p.p_promo_name
     FROM promotion p
     JOIN catalog_sales cs ON cs.cs_item_sk = p.p_item_sk
     JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
     WHERE dd.d_date = c.the_date
     ORDER BY p.p_start_date_sk DESC
     LIMIT 1) AS latest_promo,
    SUM(c.net_margin) OVER (PARTITION BY c.store_sk ORDER BY c.the_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_margin,
    REGEXP_REPLACE(c.store_name, '\\s+', ' ') AS clean_store_name
  FROM combined_sales_returns c
  WHERE c.rn <= 10
),
unioned AS (
  SELECT * FROM final_metrics
  UNION ALL
  SELECT
    NULL AS store_sk,
    NULL AS store_name,
    DATE '1900-01-01' AS the_date,
    NULL AS the_year,
    0.0 AS net_margin,
    0 AS sales_cnt,
    0 AS return_cnt,
    NULL AS volume_category,
    0 AS rn,
    NULL AS profit_ratio,
    'N/A' AS vol_return_desc,
    'N/A' AS spend_category,
    FALSE AS has_catalog_sales,
    0.0 AS avg_profit_last_30d,
    NULL AS latest_promo,
    0.0 AS cumulative_margin,
    NULL AS clean_store_name
  FROM (SELECT 1) dummy
)
SELECT
  u.store_name,
  u.clean_store_name,
  u.the_date,
  u.net_margin,
  u.cumulative_margin,
  u.profit_ratio,
  u.spend_category,
  u.vol_return_desc,
  COALESCE(u.avg_profit_last_30d, 0) AS avg_profit_last_30d,
  u.latest_promo,
  CASE
    WHEN u.latest_promo IS NULL THEN 'NO_PROMO'
    WHEN u.spend_category = 'HIGH_SPEND' THEN 'QUALIFIED'
    ELSE 'UNQUALIFIED'
  END AS promo_qualification
FROM unioned u
WHERE u.net_margin > 0 OR u.spend_category = 'LOW_SPEND'
ORDER BY u.the_date DESC, u.net_margin DESC
LIMIT 100
