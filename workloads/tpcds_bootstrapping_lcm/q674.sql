WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        s.s_store_name AS store_name,
        d.d_year AS year,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
        (cc.cc_tax_percentage + s.s_tax_percentage) / 2.0 AS avg_tax_percentage
    FROM call_center cc
    JOIN catalog_sales cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN date_dim d_cc_close
        ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d.d_year = 2001
      AND d_cc_close.d_year = 2000
      AND d_cc_open.d_year = 1999
    GROUP BY
        cc.cc_name,
        s.s_store_name,
        d.d_year,
        cc.cc_tax_percentage,
        s.s_tax_percentage
)
SELECT
    call_center_name,
    store_name,
    year,
    catalog_orders,
    catalog_net_paid,
    web_orders,
    web_net_paid,
    total_net_profit,
    avg_shipping_delay_days,
    avg_tax_percentage,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
