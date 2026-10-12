WITH sampled_sales AS (
    SELECT cs_ship_mode_sk,
           cs_quantity,
           cs_wholesale_cost,
           cs_list_price,
           cs_coupon_amt,
           cs_ext_sales_price,
           cs_net_profit
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 1
      AND cs_wholesale_cost > 20
      AND cs_list_price < 200
      AND cs_coupon_amt BETWEEN 0 AND 5000
),
aggregated_sales AS (
    SELECT cs_ship_mode_sk,
           SUM(cs_ext_sales_price) AS total_sales,
           AVG(cs_net_profit) AS avg_profit,
           COUNT(*) AS cnt
    FROM sampled_sales
    GROUP BY cs_ship_mode_sk
),
ship_modes_filtered AS (
    SELECT sm_ship_mode_sk,
           sm_ship_mode_id,
           sm_type,
           sm_carrier,
           sm_contract
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'GROUND')
      AND sm_carrier LIKE 'U%'
      AND sm_contract IS NOT NULL
      AND sm_ship_mode_id LIKE 'AAAAAAA%'
),
joined AS (
    SELECT a.cs_ship_mode_sk,
           a.total_sales,
           a.avg_profit,
           a.cnt,
           s.sm_ship_mode_id,
           s.sm_type,
           s.sm_carrier,
           s.sm_contract
    FROM aggregated_sales a
    JOIN ship_modes_filtered s
      ON a.cs_ship_mode_sk = s.sm_ship_mode_sk
),
cross_joined AS (
    SELECT j.*, v.dummy_val
    FROM joined j
    CROSS JOIN (VALUES 1, 2, 3) AS v(dummy_val)
),
intersect_keys AS (
    SELECT cs_ship_mode_sk AS ship_mode_sk
    FROM aggregated_sales
    INTERSECT
    SELECT sm_ship_mode_sk
    FROM ship_modes_filtered
),
final AS (
    SELECT cs_ship_mode_sk,
           sm_ship_mode_id,
           SUM(total_sales) AS sum_sales,
           AVG(avg_profit) AS avg_profit_over_groups,
           COUNT(*) AS num_rows,
           SUM(dummy_val) AS dummy_sum
    FROM cross_joined
    WHERE cs_ship_mode_sk IN (SELECT ship_mode_sk FROM intersect_keys)
    GROUP BY cs_ship_mode_sk, sm_ship_mode_id
    HAVING SUM(total_sales) > 1000
)
SELECT cs_ship_mode_sk,
       sm_ship_mode_id,
       sum_sales,
       avg_profit_over_groups,
       num_rows,
       dummy_sum
FROM final
ORDER BY sum_sales DESC
LIMIT 100
