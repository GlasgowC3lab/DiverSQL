WITH agg_sales AS (
  SELECT
    hd.hd_demo_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_quantity >= 30
    AND hd.hd_dep_count <= 5
  GROUP BY hd.hd_demo_sk
),
agg_coupons AS (
  SELECT
    hd.hd_demo_sk,
    SUM(ss.ss_coupon_amt) AS total_coupons,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_coupon_amt > 500
    AND hd.hd_income_band_sk IN (1, 3, 13)
  GROUP BY hd.hd_demo_sk
)
SELECT
  ks.hd_demo_sk,
  a.total_sales,
  a.total_profit,
  a.sales_cnt,
  a.profit_flag,
  ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS row_num
FROM (
  (SELECT hd_demo_sk FROM agg_sales
   EXCEPT
   SELECT hd_demo_sk FROM agg_coupons)
  INTERSECT
  SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count > 1
) ks
JOIN agg_sales a
  ON ks.hd_demo_sk = a.hd_demo_sk
ORDER BY row_num
LIMIT 100
