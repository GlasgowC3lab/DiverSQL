SELECT
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_sold.d_month_seq,
    st.s_state,
    hd_bill.hd_vehicle_count,
    hd_bill.hd_income_band_sk,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    COUNT(DISTINCT wr.wr_order_number) AS total_return_orders,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    AVG(COALESCE(wr.wr_fee, 0)) AS avg_return_fee,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(COALESCE(wr.wr_net_loss, 0)) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS loss_to_sales_ratio
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
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_closed
    ON st.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_year = 2001
  AND st.s_state IN ('CA','TX','NY')
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_sold.d_month_seq,
    st.s_state,
    hd_bill.hd_vehicle_count,
    hd_bill.hd_income_band_sk
HAVING COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY total_sales_amount DESC
LIMIT 100
