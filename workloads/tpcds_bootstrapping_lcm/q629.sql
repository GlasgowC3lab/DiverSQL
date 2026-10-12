SELECT
    ds_sold.d_year,
    ds_sold.d_month_seq,
    ds_sold.d_year * 100 + ds_sold.d_month_seq AS year_month_id,
    sm.sm_type,
    s.s_state,
    CASE WHEN s.s_state IN ('CA','NY','FL','TX') THEN 'Major' ELSE 'Other' END AS store_category,
    CONCAT(sm.sm_type, '-', s.s_state) AS ship_state_key,
    MAX(ds_ship.d_week_seq) AS max_ship_week_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    SUM(wr.wr_return_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS return_rate,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category
FROM web_sales ws
JOIN date_dim ds_sold
    ON ws.ws_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_ship
    ON ws.ws_ship_date_sk = ds_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
JOIN date_dim dr_return
    ON wr.wr_returned_date_sk = dr_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr_return.d_date_sk
WHERE ds_sold.d_year >= 2000
GROUP BY
    ds_sold.d_year,
    ds_sold.d_month_seq,
    sm.sm_type,
    s.s_state,
    CASE WHEN s.s_state IN ('CA','NY','FL','TX') THEN 'Major' ELSE 'Other' END,
    CONCAT(sm.sm_type, '-', s.s_state)
ORDER BY
    ds_sold.d_year,
    ds_sold.d_month_seq,
    sm.sm_type
