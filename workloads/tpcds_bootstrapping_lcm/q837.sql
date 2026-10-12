SELECT
    cc.cc_call_center_sk,
    cc.cc_name AS call_center_name,
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(p.p_cost) AS max_promo_cost,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    DATE_DIFF('day', d_sold.d_date, d_cc_closed.d_date)        AS days_sale_to_closed,
    CASE
        WHEN SUM(cs.cs_net_profit) = 0 THEN NULL
        ELSE SUM(cs.cs_net_paid) / SUM(cs.cs_net_profit)
    END AS paid_to_profit_ratio
FROM catalog_sales cs
JOIN call_center cc
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
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_sold.d_date,
    d_cc_closed.d_date
ORDER BY total_net_paid DESC
LIMIT 100
