SELECT
    t.d_year,
    t.ca_state,
    t.i_category,
    SUM(t.net_profit) AS total_net_profit,
    SUM(t.quantity) AS total_quantity
FROM (
    SELECT d.d_year,
           ca.ca_state,
           i.i_category,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           i.i_category,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           i.i_category,
           ws.ws_net_profit AS net_profit,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
GROUP BY t.d_year, t.ca_state, t.i_category
ORDER BY total_net_profit DESC
LIMIT 100
