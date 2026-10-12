SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    DATE_DIFF('day', d_sold.d_date, d_ship.d_date) AS ship_delay_days,
    CASE
        WHEN DATE_DIFF('day', d_sold.d_date, d_ship.d_date) <= 1 THEN 'Same Day'
        WHEN DATE_DIFF('day', d_sold.d_date, d_ship.d_date) <= 3 THEN 'Fast'
        WHEN DATE_DIFF('day', d_sold.d_date, d_ship.d_date) <= 7 THEN 'Normal'
        ELSE 'Slow'
    END AS delay_category,
    ws.ws_ext_sales_price,
    ws.ws_ext_wholesale_cost,
    (ws.ws_ext_sales_price - ws.ws_ext_wholesale_cost) AS gross_profit,
    RANK() OVER (PARTITION BY d_sold.d_year, d_sold.d_month_seq ORDER BY DATE_DIFF('day', d_sold.d_date, d_ship.d_date) DESC) AS delay_rank_in_month,
    w.web_state,
    w.web_name
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE d_sold.d_year = 2022
  AND ws.ws_quantity > 0
ORDER BY delay_rank_in_month ASC, ws.ws_order_number
LIMIT 200
