WITH cc_filtered AS (
   SELECT cc_call_center_sk,
          cc_name,
          cc_state,
          cc_city,
          cc_manager,
          cc_gmt_offset,
          cc_employees,
          cc_sq_ft,
          cc_tax_percentage
   FROM call_center
   WHERE cc_state IN ('CA','TX','NY','FL','WA')
     AND cc_city LIKE '%City%'
     AND cc_gmt_offset > -5.0
     AND cc_employees > 100
     AND cc_sq_ft BETWEEN 5000 AND 20000
     AND cc_tax_percentage < 8.0
),
wh_filtered AS (
   SELECT w_warehouse_sk,
          w_warehouse_name,
          w_state,
          w_city,
          w_gmt_offset,
          w_warehouse_sq_ft,
          w_country
   FROM warehouse
   WHERE w_state IN ('CA','TX','NY','FL','WA')
     AND w_city LIKE '%City%'
     AND w_gmt_offset > -5.0
     AND w_warehouse_sq_ft > 10000
     AND w_gmt_offset < 3.0
     AND w_country = 'USA'
),
sales_agg AS (
   SELECT cs_call_center_sk,
          cs_warehouse_sk,
          SUM(cs_net_paid)       AS total_net_paid,
          SUM(cs_net_profit)     AS total_profit,
          COUNT(*)               AS order_cnt,
          AVG(cs_wholesale_cost) AS avg_wholesale_cost
   FROM catalog_sales
   WHERE cs_wholesale_cost BETWEEN 20 AND 90
     AND cs_quantity > 1
     AND cs_ship_addr_sk IN (4818292, 702119, 1128744)
     AND cs_ext_tax > 0
     AND cs_coupon_amt < 100
     AND cs_net_paid > 0
   GROUP BY cs_call_center_sk, cs_warehouse_sk
),
full_cc_wh AS (
   SELECT cc.cc_call_center_sk,
          cc.cc_name,
          cc.cc_state,
          cc.cc_city,
          wh.w_warehouse_sk,
          wh.w_warehouse_name,
          wh.w_state,
          wh.w_city
   FROM cc_filtered cc
   FULL OUTER JOIN wh_filtered wh
        ON cc.cc_state = wh.w_state
),
key_set_with_sales AS (
   SELECT DISTINCT cs_call_center_sk
   FROM catalog_sales
),
key_set_without_sales AS (
   SELECT cc_call_center_sk
   FROM call_center
   WHERE cc_employees > 120
),
key_diff AS (
   SELECT cc_call_center_sk
   FROM key_set_without_sales
   EXCEPT
   SELECT cs_call_center_sk
   FROM key_set_with_sales
),
final AS (
   SELECT f.cc_call_center_sk,
          f.cc_name,
          f.w_warehouse_sk,
          f.w_warehouse_name,
          COALESCE(sa.total_net_paid, 0) AS total_net_paid,
          COALESCE(sa.total_profit, 0)   AS total_profit,
          COALESCE(sa.order_cnt, 0)      AS order_cnt,
          ROW_NUMBER() OVER (ORDER BY COALESCE(sa.total_profit, 0) DESC)               AS global_row_num,
          RANK()       OVER (PARTITION BY f.cc_state ORDER BY COALESCE(sa.total_profit, 0) DESC) AS state_rank,
          DENSE_RANK() OVER (PARTITION BY f.cc_state ORDER BY COALESCE(sa.total_profit, 0) DESC) AS state_dense_rank
   FROM full_cc_wh f
   LEFT JOIN sales_agg sa
          ON f.cc_call_center_sk = sa.cs_call_center_sk
         AND f.w_warehouse_sk   = sa.cs_warehouse_sk
   WHERE f.cc_call_center_sk IN (SELECT cc_call_center_sk FROM key_diff)
),
paginated AS (
   SELECT *
   FROM final
   ORDER BY total_profit DESC
   OFFSET 50 ROWS FETCH NEXT 100 ROWS ONLY
)
SELECT *
FROM paginated
LIMIT 100
