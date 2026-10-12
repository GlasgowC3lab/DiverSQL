SELECT
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    d.d_year AS year,
    d.d_year - 2000 AS year_offset,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(ws.ws_quantity) AS total_ws_quantity,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) AS net_profit_after_returns,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(cc.cc_tax_percentage * s.s_tax_percentage) AS avg_combined_tax_rate,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_price_per_unit,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    d_cc_open.d_year AS call_center_open_year
FROM date_dim d
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                     AND sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
GROUP BY
    cc.cc_state,
    s.s_state,
    d.d_year,
    d.d_year - 2000,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    d_cc_open.d_year
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
