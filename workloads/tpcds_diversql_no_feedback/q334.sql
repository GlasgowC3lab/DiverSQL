WITH demo_agg AS (
   SELECT
       hd.hd_demo_sk,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       hd.hd_buy_potential,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_fee) AS total_fee,
       COUNT(*) AS cnt_returns
   FROM catalog_returns cr
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cr.cr_return_amount > 100
     AND cr.cr_fee < 50
     AND hd.hd_buy_potential LIKE '%-5000'
     AND hd.hd_dep_count BETWEEN 1 AND 4
   GROUP BY
       hd.hd_demo_sk,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       hd.hd_buy_potential
)
SELECT
    da.hd_income_band_sk,
    da.ib_lower_bound,
    da.ib_upper_bound,
    da.hd_buy_potential,
    da.total_return_amount,
    da.total_fee,
    da.cnt_returns,
    dl.demo_total_amount
FROM demo_agg da
LEFT JOIN LATERAL (
    SELECT SUM(cr2.cr_return_amount) AS demo_total_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_refunded_hdemo_sk = da.hd_demo_sk
) dl ON true
WHERE da.total_return_amount > (
    SELECT AVG(total_return_amount) * 0.5
    FROM demo_agg
)
ORDER BY da.total_return_amount DESC, da.hd_income_band_sk
LIMIT 100
