WITH profit_agg AS (
    SELECT
        cc.cc_name AS cc_name,
        s.s_store_name AS store_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d_sold_agg ON ws.ws_sold_date_sk = d_sold_agg.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sold_agg.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold_agg.d_date_sk
    GROUP BY cc.cc_name, s.s_store_name
)
SELECT
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    d_cc_closed.d_year AS call_center_closed_year,
    d_cc_open.d_year AS call_center_open_year,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_store_closed.d_year AS store_closed_year,
    w.w_warehouse_name AS warehouse_name,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    (ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name, cc.cc_name ORDER BY ws.ws_net_profit DESC) AS profit_rank_in_store_cc,
    ws.ws_net_profit / NULLIF(pa.total_net_profit, 0) AS profit_share_of_cc_store
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN profit_agg pa ON pa.cc_name = cc.cc_name AND pa.store_name = s.s_store_name
WHERE d_sold.d_year = 2022
  AND w.w_state = 'CA'
ORDER BY profit_rank_in_store_cc
LIMIT 100
