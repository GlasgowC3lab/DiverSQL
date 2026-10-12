SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    d_sold.d_year AS sale_year,
    d_sold.d_moy AS sale_month,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    SUM(COALESCE(wr.wr_return_amt, 0)) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS return_rate
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
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_returned
    ON wr.wr_returned_date_sk = d_returned.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY ROLLUP (s.s_store_id, s.s_store_name, p.p_promo_id, p.p_promo_name, d_sold.d_year, d_sold.d_moy)
ORDER BY store_id, promo_id, sale_year, sale_month
