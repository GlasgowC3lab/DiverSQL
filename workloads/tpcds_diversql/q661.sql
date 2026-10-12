WITH sampled_sales AS (
  SELECT *
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10)
),

base_join AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_type,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    cr.cr_return_amount
  FROM sampled_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cp.cp_catalog_number IN (5, 10, 19)
    AND cp.cp_type = 'Online'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
),

sub1 AS (
  SELECT cs_order_number
  FROM base_join
  WHERE cs_quantity > 10
),

sub2 AS (
  SELECT cs_order_number
  FROM base_join
  WHERE cr_return_amount > 0
),

intersect_set AS (
  SELECT cs_order_number FROM sub1
  INTERSECT
  SELECT cs_order_number FROM sub2
),

sub3 AS (
  SELECT cs_order_number
  FROM base_join
  WHERE cs_net_paid > 1000
),

except_set AS (
  SELECT cs_order_number FROM sub3
  EXCEPT
  SELECT cs_order_number FROM intersect_set
),

union_set AS (
  SELECT cs_order_number FROM intersect_set
  UNION
  SELECT cs_order_number FROM except_set
),

agg_sub AS (
  SELECT
    bj.cp_department,
    bj.ib_lower_bound,
    COUNT(DISTINCT bj.cs_order_number) AS order_cnt,
    SUM(bj.cs_net_paid) AS total_net_paid,
    AVG(bj.cs_quantity) AS avg_quantity,
    MAX(bj.cs_net_paid) AS max_net_paid,
    MIN(bj.cs_net_paid) AS min_net_paid
  FROM base_join bj
  JOIN union_set us ON bj.cs_order_number = us.cs_order_number
  GROUP BY bj.cp_department, bj.ib_lower_bound
)

SELECT
  cp_department,
  CASE
    WHEN ib_lower_bound >= 150000 THEN 'High Income'
    WHEN ib_lower_bound >= 50000  THEN 'Mid Income'
    ELSE 'Low Income'
  END AS income_category,
  order_cnt,
  total_net_paid,
  avg_quantity,
  max_net_paid,
  min_net_paid,
  SUM(total_net_paid) OVER (PARTITION BY cp_department ORDER BY ib_lower_bound
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
FROM agg_sub
ORDER BY total_net_paid DESC
LIMIT 100
