WITH promo_time AS (
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_response_target,
        p.p_discount_active,
        t_start.t_hour AS start_hour,
        t_end.t_hour AS end_hour,
        (t_end.t_hour - t_start.t_hour) AS duration_hours
    FROM promotion p
    JOIN time_dim t_start ON p.p_start_date_sk = t_start.t_time_sk
    JOIN time_dim t_end ON p.p_end_date_sk = t_end.t_time_sk
    WHERE p.p_discount_active = 'Y'
),
store_web AS (
    SELECT
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state,
        w.web_name,
        w.web_city,
        s.s_company_id,
        s.s_market_id,
        w.web_company_id,
        w.web_mkt_id
    FROM store s
    JOIN web_site w
        ON s.s_company_id = w.web_company_id
       AND s.s_market_id = w.web_mkt_id
    WHERE s.s_number_employees > 0
)
SELECT
    sw.s_store_name,
    sw.store_city,
    sw.s_state,
    sw.web_name,
    sw.web_city,
    COUNT(DISTINCT pt.p_promo_id) AS promo_cnt,
    SUM(pt.p_cost) AS total_cost,
    AVG(pt.duration_hours) AS avg_duration,
    MAX(pt.p_response_target) AS max_response_target
FROM store_web sw
CROSS JOIN promo_time pt
WHERE pt.start_hour BETWEEN 8 AND 18
GROUP BY
    sw.s_store_name,
    sw.store_city,
    sw.s_state,
    sw.web_name,
    sw.web_city
ORDER BY total_cost DESC
LIMIT 100
