WITH sampled_site AS (
    SELECT *
    FROM web_site
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    i_sale.i_category,
    sm.sm_type,
    hd_bill.hd_buy_potential,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(sr.sr_reversed_charge) AS total_rev_charge,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM store_returns sr
JOIN item i_ret
    ON sr.sr_item_sk = i_ret.i_item_sk
JOIN household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN time_dim t_ret
    ON sr.sr_return_time_sk = t_ret.t_time_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i_ret.i_item_sk
JOIN time_dim t_sale
    ON ws.ws_sold_time_sk = t_sale.t_time_sk
JOIN item i_sale
    ON ws.ws_item_sk = i_sale.i_item_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN sampled_site ss
    ON ws.ws_web_site_sk = ss.web_site_sk
GROUP BY
    i_sale.i_category,
    sm.sm_type,
    hd_bill.hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 100
