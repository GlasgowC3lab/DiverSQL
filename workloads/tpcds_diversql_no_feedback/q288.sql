WITH start_promos AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        sd.d_date AS start_date,
        ed.d_date AS end_date,
        p.p_cost
    FROM promotion AS p
    FULL OUTER JOIN date_dim AS sd
        ON p.p_start_date_sk = sd.d_date_sk
    LEFT JOIN date_dim AS ed
        ON p.p_end_date_sk = ed.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND sd.d_year = 2021
),
end_promos AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        sd.d_date AS start_date,
        ed.d_date AS end_date,
        p.p_cost
    FROM promotion AS p
    INNER JOIN date_dim AS ed
        ON p.p_end_date_sk = ed.d_date_sk
    LEFT JOIN date_dim AS sd
        ON p.p_start_date_sk = sd.d_date_sk
    WHERE p.p_channel_email = 'Y'
      AND ed.d_year = 2021
)
SELECT
    promo_id,
    promo_name,
    start_date,
    end_date,
    cost,
    SUM(cost) OVER (PARTITION BY promo_id ORDER BY start_date ROWS UNBOUNDED PRECEDING) AS running_cost
FROM (
    SELECT p_promo_id AS promo_id, p_promo_name AS promo_name, start_date, end_date, p_cost AS cost FROM start_promos
    UNION ALL
    SELECT p_promo_id AS promo_id, p_promo_name AS promo_name, start_date, end_date, p_cost AS cost FROM end_promos
) AS combined
ORDER BY promo_id, start_date
LIMIT 100
