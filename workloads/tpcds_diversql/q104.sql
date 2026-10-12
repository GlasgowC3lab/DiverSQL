WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_qty,
            COUNT(DISTINCT inv_date_sk) AS days_count
        FROM inventory
        WHERE inv_quantity_on_hand > 0
          AND inv_warehouse_sk IN (1, 11, 15)
        GROUP BY inv_item_sk
    ),
    item_filt AS (
        SELECT
            i_item_sk,
            i_item_id,
            i_color,
            i_size,
            i_brand,
            i_current_price
        FROM item
        WHERE i_color = 'sandy'
          AND i_size = 'large'
          AND i_brand_id = 5
    ),
    promo_filt AS (
        SELECT
            p_promo_sk,
            p_item_sk,
            p_cost,
            p_promo_name,
            p_discount_active,
            p_channel_demo
        FROM promotion
        WHERE p_discount_active = 'Y'
          AND p_channel_demo = 'N'
          AND p_promo_name LIKE '%Summer%'
    ),
    common_items AS (
        SELECT i_item_sk FROM item_filt
        INTERSECT
        SELECT p_item_sk FROM promo_filt
    ),
    item_promo_full AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_color,
            i.i_size,
            p.p_promo_sk,
            p.p_cost,
            p.p_promo_name
        FROM item_filt i
        FULL OUTER JOIN promo_filt p
            ON i.i_item_sk = p.p_item_sk
    ),
    union_part AS (
        SELECT
            ip.i_item_sk,
            ip.i_item_id,
            ip.i_color,
            ip.i_size,
            ia.total_qty,
            ia.days_count,
            ip.p_promo_name,
            'source_a' AS src
        FROM item_promo_full ip
        JOIN inv_agg ia
            ON ip.i_item_sk = ia.inv_item_sk
        WHERE ip.i_color = 'sandy'
          AND ip.p_promo_name IS NOT NULL
        UNION DISTINCT
        SELECT
            ip.i_item_sk,
            ip.i_item_id,
            ip.i_color,
            ip.i_size,
            COALESCE(ia.total_qty, 0) AS total_qty,
            COALESCE(ia.days_count, 0) AS days_count,
            ip.p_promo_name,
            'source_b' AS src
        FROM item_promo_full ip
        LEFT JOIN inv_agg ia
            ON ip.i_item_sk = ia.inv_item_sk
        WHERE ip.i_color = 'sandy'
          AND ip.p_promo_name IS NULL
    )
SELECT
    up.i_item_sk,
    up.i_item_id,
    up.i_color,
    up.i_size,
    SUM(up.total_qty) AS sum_total_qty,
    AVG(up.total_qty) AS avg_total_qty,
    COUNT(DISTINCT up.src) AS distinct_sources,
    MIN(up.days_count) AS min_days,
    MAX(up.days_count) AS max_days
FROM union_part up
WHERE up.i_item_sk IN (SELECT i_item_sk FROM common_items)
GROUP BY
    up.i_item_sk,
    up.i_item_id,
    up.i_color,
    up.i_size
ORDER BY sum_total_qty DESC
LIMIT 100
