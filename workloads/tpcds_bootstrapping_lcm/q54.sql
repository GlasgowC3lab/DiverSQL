SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    hd_bill.hd_income_band_sk,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    (SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt, 0))) AS net_sales_after_returns,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_per_order,
    COUNT(wr.wr_order_number) AS total_returns,
    hd_ship.hd_vehicle_count AS ship_household_vehicle_count,
    hd_refunded.hd_dep_count AS refunded_household_dep_count,
    hd_returning.hd_vehicle_count AS returning_household_vehicle_count,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month_seq
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    hd_bill.hd_income_band_sk,
    hd_ship.hd_vehicle_count,
    hd_refunded.hd_dep_count,
    hd_returning.hd_vehicle_count,
    d_return.d_year,
    d_return.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
