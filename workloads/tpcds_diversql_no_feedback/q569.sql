WITH promo_agg AS (
    SELECT
        p_item_sk,
        p_start_date_sk,
        p_end_date_sk,
        SUM(p_cost) AS sum_cost,
        COUNT(*) AS cnt_promo
    FROM promotion
    WHERE p_purpose = 'Unknown'
      AND p_channel_press = 'N'
      AND p_channel_catalog = 'N'
    GROUP BY p_item_sk, p_start_date_sk, p_end_date_sk
),
agg AS (
    SELECT
        i.i_brand AS i_brand,
        sd.d_fy_year AS d_fy_year,
        SUM(pa.sum_cost) AS total_promo_cost,
        SUM(pa.cnt_promo) AS total_promo_cnt
    FROM promo_agg pa
    JOIN item i ON pa.p_item_sk = i.i_item_sk
    JOIN date_dim sd ON pa.p_start_date_sk = sd.d_date_sk
    JOIN date_dim ed ON pa.p_end_date_sk = ed.d_date_sk
    WHERE i.i_manufact_id IN (214, 630)
      AND sd.d_fy_year = 1901
      AND ed.d_fy_year = 1901
    GROUP BY GROUPING SETS (
        (i.i_brand, sd.d_fy_year),
        (i.i_brand),
        (sd.d_fy_year)
    )
)
SELECT
    a.i_brand,
    a.d_fy_year,
    a.total_promo_cost,
    a.total_promo_cnt,
    LAG(a.total_promo_cost) OVER (PARTITION BY a.i_brand ORDER BY a.d_fy_year) AS prev_year_cost
FROM agg a
ORDER BY a.total_promo_cost DESC
LIMIT 100
