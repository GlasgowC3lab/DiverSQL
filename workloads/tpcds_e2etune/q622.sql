WITH promo_agg AS (
    SELECT
        w.w_country AS country,
        w.w_state AS state,
        w.w_city AS city,
        COUNT(p.p_promo_id) AS promo_cnt,
        SUM(p.p_cost) AS total_cost,
        AVG(p.p_response_target) AS avg_response_target,
        COUNT(CASE WHEN p.p_channel_tv = 'Y' THEN 1 END) AS tv_promo_cnt
    FROM promotion p
    JOIN warehouse w
        ON p.p_item_sk = w.w_warehouse_sk
    WHERE p.p_cost > 1000
      AND p.p_start_date_sk >= 2458849  -- corresponds to 2020‑01‑01 in date dimension
      AND p.p_channel_tv = 'Y'
      AND w.w_gmt_offset BETWEEN -5 AND 5
    GROUP BY w.w_country, w.w_state, w.w_city
)
SELECT
    country,
    state,
    city,
    promo_cnt,
    total_cost,
    avg_response_target,
    tv_promo_cnt,
    RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
FROM promo_agg
WHERE promo_cnt >= 5
ORDER BY total_cost DESC
LIMIT 100
