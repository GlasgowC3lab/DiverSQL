SELECT
    ca.ca_state,
    ca.ca_gmt_offset,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ca.ca_address_sk) AS address_cnt,
    COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT sm.sm_ship_mode_sk) AS ship_mode_cnt,
    MIN(p.p_start_date_sk) AS earliest_start,
    MAX(p.p_end_date_sk) AS latest_end
FROM customer_address ca
JOIN promotion p
    ON p.p_channel_demo = ca.ca_state
JOIN ship_mode sm
    ON sm.sm_type = p.p_channel_tv
JOIN income_band ib
    ON p.p_response_target BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
    AND p.p_cost > 0
    AND sm.sm_carrier IS NOT NULL
GROUP BY
    ca.ca_state,
    ca.ca_gmt_offset,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING SUM(p.p_cost) > 5000
ORDER BY total_promo_cost DESC
LIMIT 100
