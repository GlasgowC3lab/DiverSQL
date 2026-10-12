SELECT
    d_sold.d_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    d_return.d_date AS return_date,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_ext_discount_amt) AS max_discount_amount
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_return.d_date
ORDER BY total_net_paid DESC
LIMIT 100
