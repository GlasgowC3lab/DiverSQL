WITH store_closure AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_closed_date_sk,
        d_closed.d_year AS closed_year,
        d_closed.d_month_seq AS closed_month
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_closed.d_year = 2021
),
active_promotions AS (
    SELECT
        p.p_promo_sk,
        p.p_cost,
        p.p_channel_tv,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM promotion p
    JOIN date_dim d_p_start
        ON p.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
),
active_catalog_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk
    FROM catalog_page cp
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
)
SELECT
    sc.s_state,
    acp.cp_department,
    COUNT(DISTINCT ap.p_promo_sk) AS promo_cnt,
    SUM(ap.p_cost) AS total_promo_cost,
    COUNT(DISTINCT acp.cp_catalog_page_sk) AS catalog_page_cnt,
    RANK() OVER (ORDER BY SUM(ap.p_cost) DESC) AS rank_by_cost
FROM store_closure sc
JOIN active_promotions ap
    ON sc.s_closed_date_sk BETWEEN ap.p_start_date_sk AND ap.p_end_date_sk
JOIN active_catalog_pages acp
    ON sc.s_closed_date_sk BETWEEN acp.cp_start_date_sk AND acp.cp_end_date_sk
WHERE acp.cp_type = 'monthly'
GROUP BY
    sc.s_state,
    acp.cp_department
ORDER BY
    total_promo_cost DESC
LIMIT 100
