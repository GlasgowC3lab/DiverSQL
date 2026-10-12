WITH sales_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        i.i_item_desc,
        w.w_city,
        w.w_state
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND w.w_city LIKE 'Pleasant%'
      AND regexp_like(i.i_item_desc, '(?i)\\b[A-Z]{2}\\d{3}\\b')
)
SELECT
    concat_ws(', ', s.w_city, s.w_state) AS warehouse_location,
    word,
    sum(s.ws_net_paid) AS total_net_paid,
    sum(s.ws_net_profit) AS total_net_profit,
    count(*) AS sales_count
FROM sales_join s
CROSS JOIN UNNEST(split(s.i_item_desc, '\\s+')) AS t(word)
WHERE word <> ''
GROUP BY
    concat_ws(', ', s.w_city, s.w_state),
    word
ORDER BY total_net_profit DESC
LIMIT 100
