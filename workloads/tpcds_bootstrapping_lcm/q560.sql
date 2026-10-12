SELECT
    d_sold.d_year,
    d_sold.d_month_seq / 3 AS quarter_index,
    i.i_category,
    s.s_state,
    CASE WHEN i.i_color = 'Red' THEN 'Red' ELSE 'Other' END AS color_group,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_qty_sold,
    SUM(wr.wr_return_quantity) AS total_qty_returned,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_return_net_loss,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    SUM(ws.ws_ext_tax) AS total_sales_tax,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(ws.ws_coupon_amt) AS total_coupon_amt,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    SUM(wr.wr_account_credit) AS total_account_credit,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_reversed_charge) AS total_reversed_charge,
    (SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt) - SUM(ws.ws_coupon_amt)) AS net_sales_after_returns,
    (SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) - SUM(wr.wr_fee) - SUM(wr.wr_reversed_charge)) AS net_profit_adjusted,
    CASE WHEN SUM(ws.ws_quantity) > 0 THEN SUM(wr.wr_return_quantity) / SUM(ws.ws_quantity) ELSE 0 END AS return_rate,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(ws.ws_ext_discount_amt) / SUM(ws.ws_ext_sales_price) ELSE 0 END AS discount_rate,
    CASE
        WHEN (SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt) - SUM(ws.ws_coupon_amt)) > 0 THEN
            (SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) - SUM(wr.wr_fee) - SUM(wr.wr_reversed_charge)) /
            (SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt) - SUM(ws.ws_coupon_amt))
        ELSE 0
    END AS profit_margin
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq / 3,
    i.i_category,
    s.s_state,
    CASE WHEN i.i_color = 'Red' THEN 'Red' ELSE 'Other' END
ORDER BY net_sales_after_returns DESC
LIMIT 100
