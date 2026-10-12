SELECT
    store.s_store_id,
    store.s_state,
    store.s_market_desc,
    promotion.p_promo_id,
    promotion.p_promo_name,
    promotion.p_discount_active,
    promotion.p_response_target,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    web_site.web_name,
    web_site.web_state,
    d_site_open.d_year AS site_open_year,
    d_site_close.d_year AS site_close_year,
    d_promo_start.d_year AS promo_start_year,
    d_promo_end.d_year AS promo_end_year,
    SUM(web_sales.ws_net_paid) AS total_net_paid,
    SUM(web_sales.ws_quantity) AS total_quantity,
    AVG(web_sales.ws_sales_price) AS avg_sales_price,
    SUM(web_sales.ws_ext_discount_amt) AS total_discount_amount,
    COUNT(DISTINCT web_sales.ws_order_number) AS distinct_orders
FROM web_sales
JOIN date_dim AS d_sold
    ON web_sales.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim AS d_ship
    ON web_sales.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site
    ON web_sales.ws_web_site_sk = web_site.web_site_sk
JOIN date_dim AS d_site_open
    ON web_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim AS d_site_close
    ON web_site.web_close_date_sk = d_site_close.d_date_sk
JOIN promotion
    ON web_sales.ws_promo_sk = promotion.p_promo_sk
JOIN date_dim AS d_promo_start
    ON promotion.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim AS d_promo_end
    ON promotion.p_end_date_sk = d_promo_end.d_date_sk
JOIN store
    ON store.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    store.s_store_id,
    store.s_state,
    store.s_market_desc,
    promotion.p_promo_id,
    promotion.p_promo_name,
    promotion.p_discount_active,
    promotion.p_response_target,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    web_site.web_name,
    web_site.web_state,
    d_site_open.d_year,
    d_site_close.d_year,
    d_promo_start.d_year,
    d_promo_end.d_year
ORDER BY
    total_net_paid DESC
LIMIT 100
