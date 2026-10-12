WITH cr_agg AS (
   SELECT
      cr_call_center_sk,
      SUM(cr_return_amount) AS sum_return_amount,
      SUM(cr_return_quantity) AS sum_return_quantity,
      AVG(cr_reversed_charge) AS avg_reversed_charge,
      COUNT(*) AS cnt_returns
   FROM catalog_returns
   WHERE cr_return_amount > 0
     AND cr_return_quantity > 0
     AND cr_reversed_charge >= 0
     AND cr_store_credit < 500
     AND cr_returning_cdemo_sk BETWEEN 400000 AND 1500000
     AND cr_warehouse_sk IS NOT NULL
   GROUP BY cr_call_center_sk
),
joined AS (
   SELECT
      cc.cc_division,
      cc.cc_market_manager,
      cc.cc_rec_end_date,
      cc.cc_sq_ft,
      cc.cc_employees,
      cr_agg.sum_return_amount,
      cr_agg.sum_return_quantity,
      cr_agg.avg_reversed_charge,
      cr_agg.cnt_returns
   FROM call_center cc
   JOIN cr_agg
     ON cc.cc_call_center_sk = cr_agg.cr_call_center_sk
   WHERE cc.cc_rec_end_date >= DATE '2000-01-01'
     AND cc.cc_rec_end_date <= DATE '2001-12-31'
     AND cc.cc_division IN (1, 2, 5, 6)
     AND cc.cc_sq_ft > 0
     AND cc.cc_employees BETWEEN 10 AND 500
)
SELECT
   cc_division,
   cc_market_manager,
   SUM(sum_return_amount) AS total_return_amount,
   SUM(sum_return_quantity) AS total_return_quantity,
   AVG(avg_reversed_charge) AS avg_reversed_charge,
   SUM(cnt_returns) AS total_returns,
   RANK() OVER (PARTITION BY cc_division ORDER BY SUM(sum_return_amount) DESC) AS division_rank
FROM joined
GROUP BY ROLLUP (cc_division, cc_market_manager)
HAVING (cc_division IS NOT NULL AND SUM(sum_return_amount) > 1000)
   OR cc_division IS NULL
ORDER BY division_rank NULLS LAST, cc_division, cc_market_manager
