WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_warehouse_sk,
        ws_sold_time_sk,
        ws_bill_hdemo_sk,
        ws_ship_hdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS line_cnt
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_net_paid_inc_tax > 500
      AND ws_ext_discount_amt < 200
    GROUP BY ws_order_number, ws_item_sk, ws_warehouse_sk, ws_sold_time_sk, ws_bill_hdemo_sk, ws_ship_hdemo_sk
)
SELECT
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END AS income_category,
    SUM(ws_agg.total_net_paid) AS sum_net_paid,
    SUM(r.wr_return_amt) AS sum_return_amt,
    COUNT(DISTINCT ws_agg.ws_order_number) AS distinct_order_cnt,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    MIN(ss.ss_quantity) AS min_store_qty
FROM ws_agg
JOIN time_dim t
    ON ws_agg.ws_sold_time_sk = t.t_time_sk
JOIN household_demographics hd_bill
    ON ws_agg.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws_agg.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns r
    ON r.wr_order_number = ws_agg.ws_order_number
   AND r.wr_item_sk = ws_agg.ws_item_sk
JOIN household_demographics hd_refunded
    ON r.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON r.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
WHERE t.t_hour = 14
  AND ib.ib_lower_bound >= 60000
  AND w.w_state = 'CA'
  AND hd_bill.hd_vehicle_count > 2
GROUP BY
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END
ORDER BY sum_net_paid DESC
LIMIT 100
