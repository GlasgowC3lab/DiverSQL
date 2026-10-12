SELECT
    cc.cc_call_center_id,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    d_sold.d_year AS sale_year,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_city AS store_city,
    d_store_closed.d_date AS store_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    d_cc_closed.d_date AS call_center_closed_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    cs.cs_net_paid_inc_tax,
    cs.cs_coupon_amt,
    (cs.cs_net_paid - cs.cs_coupon_amt) AS net_paid_minus_coupon
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_store_closed
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
ORDER BY net_paid_minus_coupon DESC
LIMIT 100
