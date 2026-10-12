SELECT
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(d_sold.d_date) AS min_sold_date,
    MAX(d_ship.d_date) AS max_ship_date,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax,
    COUNT(DISTINCT s.s_store_sk) AS store_count
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sold.d_year = 2001
  AND d_promo_start.d_date <= d_sold.d_date
  AND d_promo_end.d_date >= d_sold.d_date
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 10
