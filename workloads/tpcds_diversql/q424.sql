WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        p.p_promo_id,
        regexp_extract(p.p_promo_id, 'A{8}(.*)', 1) AS promo_suffix,
        p.p_channel_email,
        p.p_channel_details,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_manager,
        w.w_warehouse_name,
        w.w_city,
        inv.inv_quantity_on_hand,
        CASE WHEN regexp_like(p.p_promo_id, '^A{8}B') THEN 'StartsWithA8B' ELSE 'Other' END AS promo_category,
        CASE WHEN cc.cc_city LIKE '%York%' THEN 'NYC' ELSE 'OtherCity' END AS city_flag,
        substr(w.w_warehouse_name, 1, 3) AS wh_prefix,
        split(cc.cc_manager, ' ') AS manager_words
    FROM sampled_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = ss.ss_item_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND regexp_like(p.p_channel_details, '.*force.*')
),
unnested_manager AS (
    SELECT
        jd.*, 
        mgr_word
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.manager_words) AS t(mgr_word)
),
aggregated AS (
    SELECT
        wh_prefix,
        promo_category,
        city_flag,
        COUNT(*) AS cnt_sales,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(CASE WHEN ss_net_profit > 0 THEN ss_net_profit ELSE 0 END) AS positive_profit,
        COUNT(DISTINCT ss_item_sk) AS distinct_items
    FROM unnested_manager
    GROUP BY wh_prefix, promo_category, city_flag
),
warehouse_agg AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        COUNT(*) AS warehouse_sales_cnt
    FROM warehouse w
    LEFT JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY w.w_warehouse_name, w.w_city
),
full_joined AS (
    SELECT *
    FROM aggregated a
    FULL OUTER JOIN warehouse_agg wa
        ON a.wh_prefix = substr(wa.w_warehouse_name, 1, 3)
),
final AS (
    SELECT
        fj.*, 
        CASE WHEN fj.cnt_sales IS NULL THEN 0 ELSE fj.cnt_sales END AS cnt_sales_coalesce
    FROM full_joined fj
    WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_id = fj.promo_category
          AND p2.p_discount_active = 'Y'
    )
)
SELECT *
FROM final
LIMIT 100
