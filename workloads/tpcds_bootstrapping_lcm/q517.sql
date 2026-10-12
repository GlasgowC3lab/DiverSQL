WITH agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_manager,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_name,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_quarter_seq,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_manager,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_name,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_quarter_seq
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_manager,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    p_promo_name,
    d_date,
    d_day_name,
    d_month_seq,
    d_quarter_seq,
    total_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_inventory_on_hand DESC) AS inventory_rank
FROM agg
ORDER BY total_inventory_on_hand DESC
LIMIT 100
