SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_country,
    cc.cc_call_center_id,
    cc.cc_division_name,
    cc.cc_manager,
    p.p_promo_name,
    p.p_channel_tv,
    d_common.d_year AS common_year,
    d_common.d_month_seq AS common_month,
    d_cc_open.d_year AS cc_open_year,
    d_p_end.d_year AS promo_end_year,
    d_c_ship.d_year AS cust_first_ship_year,
    d_c_last_review.d_year AS cust_last_review_year,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(s.s_floor_space) AS total_store_floor_space,
    SUM(cc.cc_sq_ft) AS total_call_center_sqft,
    SUM(s.s_number_employees) + SUM(cc.cc_employees) AS total_employees,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    CASE 
        WHEN cc.cc_tax_percentage > 5.00 THEN 'HighTax' 
        ELSE 'LowTax' 
    END AS tax_category,
    CASE 
        WHEN p.p_discount_active = 'Y' THEN 'DiscountActive' 
        ELSE 'NoDiscount' 
    END AS discount_status
FROM store s
JOIN date_dim d_common ON s.s_closed_date_sk = d_common.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_common.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_common.d_date_sk
JOIN customer c ON c.c_first_sales_date_sk = d_common.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN date_dim d_c_ship ON c.c_first_shipto_date_sk = d_c_ship.d_date_sk
JOIN date_dim d_c_last_review ON c.c_last_review_date = d_c_last_review.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_country,
    cc.cc_call_center_id,
    cc.cc_division_name,
    cc.cc_manager,
    p.p_promo_name,
    p.p_channel_tv,
    d_common.d_year,
    d_common.d_month_seq,
    d_cc_open.d_year,
    d_p_end.d_year,
    d_c_ship.d_year,
    d_c_last_review.d_year,
    CASE 
        WHEN cc.cc_tax_percentage > 5.00 THEN 'HighTax' 
        ELSE 'LowTax' 
    END,
    CASE 
        WHEN p.p_discount_active = 'Y' THEN 'DiscountActive' 
        ELSE 'NoDiscount' 
    END
