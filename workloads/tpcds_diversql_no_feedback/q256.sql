WITH sales_orders AS (
   SELECT ws.ws_order_number
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ws.ws_wholesale_cost > 20
     AND ws.ws_quantity >= 2
     AND p.p_discount_active = 'Y'
     AND ib.ib_lower_bound >= 50000
),
return_orders AS (
   SELECT wr.wr_order_number AS ws_order_number
   FROM web_returns wr
   JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
   JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
   WHERE wr.wr_return_amt > 100
     AND wr.wr_refunded_cash > 50
     AND ib2.ib_upper_bound <= 100000
     AND hd2.hd_vehicle_count >= 1
),
intersected_orders AS (
   SELECT ws_order_number FROM sales_orders
   INTERSECT
   SELECT ws_order_number FROM return_orders
),
promo_agg AS (
   SELECT p.p_promo_id,
          COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
          SUM(ws.ws_net_profit) AS total_profit,
          AVG(ws.ws_net_profit) AS avg_profit
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN intersected_orders io ON ws.ws_order_number = io.ws_order_number
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE p.p_channel_tv = 'Y'
     AND hd.hd_buy_potential = '1001-5000'
   GROUP BY p.p_promo_id
),
small_income AS (
   SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
   FROM income_band
   WHERE ib_lower_bound < 30000
   LIMIT 5
)
SELECT pa.p_promo_id,
       pa.order_cnt,
       pa.total_profit,
       si.ib_income_band_sk,
       si.ib_lower_bound,
       si.ib_upper_bound
FROM promo_agg pa
CROSS JOIN small_income si
ORDER BY pa.total_profit DESC
LIMIT 20
