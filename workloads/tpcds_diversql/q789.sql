WITH sampled_sales AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
filtered_sales AS (
   SELECT *
   FROM sampled_sales
   WHERE ss_net_paid_inc_tax > 500
     AND ss_quantity BETWEEN 1 AND 5
     AND ss_wholesale_cost < 80
     AND ss_list_price >= 10
     AND ss_ext_tax > 0
     AND ss_coupon_amt = 0
),
hd_filtered AS (
   SELECT *
   FROM household_demographics
   WHERE hd_dep_count <= 5
     AND hd_vehicle_count >= 1
     AND hd_buy_potential IN ('0-500', '501-1000', '>10000')
),
joined AS (
   SELECT
       COALESCE(fs.ss_hdemo_sk, hd.hd_demo_sk) AS demo_key,
       hd.hd_buy_potential,
       hd.hd_dep_count,
       hd.hd_vehicle_count,
       fs.ss_sold_date_sk,
       fs.ss_net_paid_inc_tax,
       fs.ss_quantity,
       fs.ss_list_price,
       fs.ss_wholesale_cost,
       fs.ss_ext_sales_price
   FROM hd_filtered hd
   FULL OUTER JOIN filtered_sales fs
       ON fs.ss_hdemo_sk = hd.hd_demo_sk
),
joined_with_avg AS (
   SELECT
       j.*,
       avg_demo.avg_net_paid_inc_tax
   FROM joined j
   LEFT JOIN LATERAL (
       SELECT avg(ss_net_paid_inc_tax) AS avg_net_paid_inc_tax
       FROM filtered_sales fs2
       WHERE fs2.ss_hdemo_sk = j.demo_key
   ) avg_demo ON true
),
final AS (
   SELECT
       jw.demo_key,
       jw.hd_buy_potential,
       jw.hd_dep_count,
       jw.hd_vehicle_count,
       jw.ss_sold_date_sk,
       jw.ss_net_paid_inc_tax,
       jw.ss_quantity,
       jw.ss_list_price,
       jw.ss_wholesale_cost,
       jw.ss_ext_sales_price,
       jw.avg_net_paid_inc_tax,
       CASE
           WHEN jw.ss_net_paid_inc_tax > jw.avg_net_paid_inc_tax THEN 'Above Avg'
           ELSE 'Below Avg'
       END AS payment_category,
       ROW_NUMBER() OVER (PARTITION BY jw.hd_buy_potential ORDER BY jw.ss_net_paid_inc_tax DESC) AS rn_by_potential
   FROM joined_with_avg jw
   WHERE EXISTS (
       SELECT 1 FROM filtered_sales fs3
       WHERE fs3.ss_hdemo_sk = jw.demo_key
         AND fs3.ss_net_paid_inc_tax > jw.ss_net_paid_inc_tax
   )
)
SELECT
   demo_key,
   hd_buy_potential,
   hd_dep_count,
   hd_vehicle_count,
   ss_sold_date_sk,
   ss_net_paid_inc_tax,
   ss_quantity,
   ss_list_price,
   ss_wholesale_cost,
   ss_ext_sales_price,
   avg_net_paid_inc_tax,
   payment_category,
   rn_by_potential
FROM final
WHERE rn_by_potential <= 10
ORDER BY hd_buy_potential ASC, ss_net_paid_inc_tax DESC
OFFSET 0
LIMIT 100
