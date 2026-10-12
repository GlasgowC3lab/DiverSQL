SELECT
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_channel_tv,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_weekend,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    wp.wp_url,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_discount_amt) AS net_sales_excluding_discount,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_web_access
    ON wp.wp_access_date_sk = d_web_access.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_sold.d_year = 2022
GROUP BY
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_channel_tv,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_weekend,
    d_promo_start.d_date,
    d_promo_end.d_date,
    wp.wp_url,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
