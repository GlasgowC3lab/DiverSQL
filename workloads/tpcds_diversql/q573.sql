WITH cs_agg AS (
   SELECT
       cs.cs_bill_hdemo_sk AS hd_demo_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   WHERE cs.cs_quantity > 1
     AND cs.cs_wholesale_cost > 20
     AND cs.cs_sold_date_sk >= 2450000
   GROUP BY cs.cs_bill_hdemo_sk
),
sr_agg AS (
   SELECT
       sr.sr_hdemo_sk,
       SUM(sr.sr_return_amt) AS total_return_amt,
       SUM(sr.sr_fee) AS total_fee,
       COUNT(*) AS return_cnt,
       MIN(sr.sr_reason_sk) AS reason_sk
   FROM store_returns sr
   WHERE sr.sr_return_quantity > 0
     AND sr.sr_return_amt > 30
     AND sr.sr_fee < 80
   GROUP BY sr.sr_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    cs.total_sales,
    cs.total_profit,
    sr.total_return_amt,
    sr.total_fee,
    r.r_reason_desc,
    CASE
        WHEN cs.total_profit > 5000 THEN 'HIGH'
        WHEN cs.total_profit IS NULL THEN 'NO_SALES'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY COALESCE(cs.total_sales, 0) DESC) AS sales_rank,
    CASE WHEN u.ord = 1 THEN 'reason_id' ELSE 'reason_desc' END AS reason_attribute,
    u.reason_value
FROM cs_agg cs
FULL OUTER JOIN sr_agg sr
    ON cs.hd_demo_sk = sr.sr_hdemo_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = COALESCE(cs.hd_demo_sk, sr.sr_hdemo_sk)
LEFT JOIN reason r
    ON r.r_reason_sk = sr.reason_sk
LEFT JOIN LATERAL (
    SELECT *
    FROM UNNEST(ARRAY[ r.r_reason_id, r.r_reason_desc ]) WITH ORDINALITY AS t(reason_value, ord)
) u ON true
WHERE hd.hd_income_band_sk IN (3, 4, 7)
  AND (cs.total_sales IS NULL OR cs.total_sales > 1000)
  AND (sr.total_return_amt IS NULL OR sr.total_return_amt < 5000)
ORDER BY sales_rank
LIMIT 100
