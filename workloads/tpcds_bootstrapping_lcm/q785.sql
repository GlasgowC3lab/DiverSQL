SELECT
    d_sales.d_date AS sales_date,
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_channel_event,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date   AS promo_end_date,
    COUNT(DISTINCT ws.ws_order_number)                     AS total_orders,
    SUM(ws.ws_ext_sales_price)                             AS total_sales,
    SUM(ws.ws_net_profit)                                  AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0))                     AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0))                AS total_return_qty,
    (SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt, 0))) AS net_sales_after_returns,
    AVG(ws.ws_ext_discount_amt)                            AS avg_discount,
    MIN(p.p_cost)                                          AS min_promo_cost,
    MAX(p.p_cost)                                          AS max_promo_cost
FROM date_dim d_sales
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk      = ws.ws_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    d_sales.d_date,
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_channel_event,
    d_promo_start.d_date,
    d_promo_end.d_date
ORDER BY total_net_profit DESC
LIMIT 100
