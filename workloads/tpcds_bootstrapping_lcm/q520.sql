SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_country,
    cc.cc_state,
    s.s_state AS store_state,
    s.s_city,
    CASE
        WHEN ws.ws_sales_price * ws.ws_quantity > 1000 THEN 'high'
        ELSE 'low'
    END AS sales_volume_category,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_order_count,
    COUNT(DISTINCT s.s_store_sk) AS distinct_store_count,
    COUNT(DISTINCT cc.cc_call_center_sk) AS distinct_call_center_count
FROM
    call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
WHERE
    ws.ws_quantity > 0
    AND i.inv_quantity_on_hand >= 0
    AND cc.cc_country = 'United States'
    AND d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    cc.cc_country,
    cc.cc_state,
    s.s_state,
    s.s_city,
    CASE
        WHEN ws.ws_sales_price * ws.ws_quantity > 1000 THEN 'high'
        ELSE 'low'
    END
HAVING
    SUM(ws.ws_quantity) > 100
ORDER BY
    d.d_year,
    d.d_month_seq,
    total_sales_amount DESC
LIMIT 100
