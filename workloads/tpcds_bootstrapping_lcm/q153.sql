SELECT
    cc.cc_company_name,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_ship.d_date AS ship_date,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS profit_margin,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(d_sales.d_date) AS last_sale_date,
    d_cc_closed.d_date AS call_center_closed,
    d_cc_open.d_date AS call_center_opened,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
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
JOIN store s
  ON s.s_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sales.d_year = 2022
  AND cc.cc_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_company_name,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_ship.d_date,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date
ORDER BY profit_margin DESC
LIMIT 100
