WITH agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_manager,
        d_cc_open.d_date AS cc_open_date,
        d_sold.d_date AS cc_closed_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        d_sold.d_year AS sales_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay,
        CASE
            WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
            ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)
        END AS profit_margin
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_manager,
        d_cc_open.d_date,
        d_sold.d_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sold.d_year
)
SELECT
    cc_call_center_id,
    call_center_name,
    cc_manager,
    cc_open_date,
    cc_closed_date,
    s_store_id,
    s_store_name,
    store_city,
    sales_year,
    total_orders,
    total_sales,
    total_net_profit,
    avg_shipping_delay,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
