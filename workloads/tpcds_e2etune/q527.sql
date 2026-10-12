WITH sales_by_store AS (
   SELECT
      ss.ss_store_sk,
      sm.sm_type,
      sm.sm_carrier,
      SUM(ss.ss_net_profit) AS total_net_profit,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS transaction_count,
      AVG(ss.ss_quantity) AS avg_quantity
   FROM store_sales ss
   JOIN ship_mode sm
     ON ((ss.ss_sold_date_sk % 5) + 1) = sm.sm_ship_mode_sk
   WHERE sm.sm_type = 'EXPRESS'
     AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
   GROUP BY ss.ss_store_sk, sm.sm_type, sm.sm_carrier
)
SELECT
   ss_store_sk,
   sm_type,
   sm_carrier,
   total_net_profit,
   total_sales,
   transaction_count,
   avg_quantity,
   ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_by_store
WHERE total_net_profit > 0
ORDER BY profit_rank
LIMIT 20
