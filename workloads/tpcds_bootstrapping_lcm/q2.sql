WITH daily_inventory AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        cc.cc_call_center_sk,
        cc.cc_name AS call_center_name,
        cc.cc_tax_percentage,
        s.s_store_sk,
        s.s_store_name,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_tax_percentage,
        s.s_store_sk,
        s.s_store_name
)
SELECT
    di.d_date,
    di.d_day_name,
    CASE WHEN di.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    di.call_center_name,
    di.s_store_name,
    di.total_quantity,
    di.distinct_items,
    (di.total_quantity * di.cc_tax_percentage) AS tax_estimate,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count,
    wp.wp_image_count,
    wp.wp_link_count,
    ROW_NUMBER() OVER (PARTITION BY di.call_center_name ORDER BY di.total_quantity DESC) AS inventory_rank_by_center
FROM daily_inventory di
JOIN web_page wp ON wp.wp_creation_date_sk = di.d_date_sk
WHERE di.total_quantity > 0
ORDER BY tax_estimate DESC, di.d_date DESC
LIMIT 200
