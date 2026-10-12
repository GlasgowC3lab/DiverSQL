SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ws.ws_sold_date_sk AS sale_date_key,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(t.t_hour) AS earliest_sale_hour,
    MAX(t.t_hour) AS latest_sale_hour,
    COUNT(DISTINCT wp.wp_type) AS distinct_page_types
FROM web_sales ws
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
WHERE
    t.t_shift = 'Evening'
    AND c.c_birth_year BETWEEN 1960 AND 1985
    AND ca.ca_country = 'United States'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ws.ws_sold_date_sk
HAVING
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) > 1000
ORDER BY
    net_profit_after_returns DESC
LIMIT 10
