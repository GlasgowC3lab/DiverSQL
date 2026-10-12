WITH combined AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_city AS call_center_city,
        cc.cc_state AS call_center_state,
        s.s_store_id,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d_common.d_date AS common_date,
        d_common.d_year AS year,
        d_common.d_month_seq AS month_seq,
        d_open.d_date AS call_center_open_date,
        d_promo_end.d_date AS promo_end_date,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promo_count
    FROM call_center cc
    JOIN date_dim d_common
        ON cc.cc_closed_date_sk = d_common.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_common.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_common.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_common.d_date_sk
    LEFT JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_state,
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_common.d_date,
        d_common.d_year,
        d_common.d_month_seq,
        d_open.d_date,
        d_promo_end.d_date
)
SELECT
    cc_call_center_id,
    call_center_city,
    call_center_state,
    s_store_id,
    store_city,
    store_state,
    common_date,
    year,
    month_seq,
    call_center_open_date,
    promo_end_date,
    total_inventory_qty,
    total_promo_cost,
    distinct_promo_count,
    ROW_NUMBER() OVER (PARTITION BY common_date ORDER BY total_inventory_qty DESC) AS inventory_rank
FROM combined
ORDER BY inventory_rank, total_inventory_qty DESC
LIMIT 100
