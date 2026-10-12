SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    s.s_state AS store_state,
    hd_bill.hd_income_band_sk AS bill_income_band,
    hd_ship.hd_income_band_sk AS ship_income_band,
    CASE
        WHEN hd_bill.hd_income_band_sk >= 5 THEN 'HighIncome'
        ELSE 'LowIncome'
    END AS income_band_category,
    CASE
        WHEN hd_bill.hd_income_band_sk = hd_ship.hd_income_band_sk THEN 'Match'
        ELSE 'Mismatch'
    END AS income_band_match,
    CASE
        WHEN s.s_closed_date_sk IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS store_status,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS adjusted_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    (SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS discount_ratio,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    (SUM(COALESCE(wr.wr_return_quantity, 0)) / NULLIF(SUM(ws.ws_quantity), 0)) AS return_rate,
    (SUM(ws.ws_ext_tax) + COALESCE(SUM(wr.wr_return_tax), 0)) AS total_tax,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    SUM(ws.ws_coupon_amt) AS total_coupon_amount,
    SUM(ws.ws_ext_list_price) - SUM(ws.ws_ext_sales_price) AS list_price_gap
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    hd_bill.hd_income_band_sk,
    hd_ship.hd_income_band_sk,
    s.s_closed_date_sk
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY total_sales_amount DESC
LIMIT 100
