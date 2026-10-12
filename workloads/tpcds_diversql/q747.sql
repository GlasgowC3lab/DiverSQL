WITH joined_all AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_sk,
        i.i_class,
        i.i_formulation,
        i.i_current_price,
        p.p_promo_sk,
        p.p_discount_active,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        sr.sr_return_amt_inc_tax,
        sr.sr_store_sk,
        t.t_hour,
        w.w_state,
        w.w_warehouse_sk
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_buy_potential IN ('>10000', '5001-10000')
      AND hd.hd_dep_count >= 5
      AND i.i_class = 'pants'
      AND i.i_formulation LIKE '%steel%'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
),
array_expanded AS (
    SELECT
        ja.*,
        ARRAY[ja.hd_dep_count, ja.hd_vehicle_count] AS dep_vehicle_arr
    FROM joined_all ja
),
unnested_counts AS (
    SELECT
        ae.*, 
        uv.value            AS dep_or_vehicle,
        uv.ordinality       AS position   -- 1 = dep, 2 = vehicle
    FROM array_expanded ae
    CROSS JOIN UNNEST(ae.dep_vehicle_arr) WITH ORDINALITY AS uv(value, ordinality)
),
final_agg AS (
    SELECT
        uc.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT uc.i_item_sk)                         AS distinct_items_sold,
        SUM(uc.ss_net_profit)                               AS total_net_profit,
        SUM(uc.sr_return_amt_inc_tax)                       AS total_return_inc_tax,
        AVG(CASE WHEN uc.position = 1 THEN uc.dep_or_vehicle END) AS avg_dep_count,
        AVG(CASE WHEN uc.position = 2 THEN uc.dep_or_vehicle END) AS avg_vehicle_count
    FROM unnested_counts uc
    JOIN income_band ib
        ON uc.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        uc.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    fa.hd_income_band_sk,
    fa.ib_lower_bound,
    fa.ib_upper_bound,
    fa.distinct_items_sold,
    fa.total_net_profit,
    fa.total_return_inc_tax,
    fa.avg_dep_count,
    fa.avg_vehicle_count,
    CASE WHEN fa.total_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    sd.w_state
FROM final_agg fa
CROSS JOIN (
    SELECT DISTINCT w_state
    FROM warehouse
    WHERE w_state IN ('CA', 'TX', 'NY')
) sd
ORDER BY fa.total_net_profit DESC, fa.hd_income_band_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
