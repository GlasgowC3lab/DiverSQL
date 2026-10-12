SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_division,
    s.s_division_id,
    cc.cc_state || '-' || s.s_state AS region_pair,
    cc.cc_employees % 100 AS employee_mod_100,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_cnt,
    COUNT(DISTINCT s.s_store_sk) AS store_cnt,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS discounted_promo_cost,
    AVG(s.s_tax_percentage - cc.cc_tax_percentage) AS avg_tax_diff,
    MIN(p.p_start_date_sk) AS min_promo_start_sk,
    MAX(p.p_end_date_sk) AS max_promo_end_sk
FROM
    date_dim d
INNER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
INNER JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
INNER JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_month_seq,
    cc.cc_division,
    s.s_division_id,
    cc.cc_state || '-' || s.s_state,
    cc.cc_employees % 100
