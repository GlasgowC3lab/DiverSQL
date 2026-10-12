WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_quantity,
           AVG(inv_quantity_on_hand) AS avg_quantity
    FROM inventory
    WHERE inv_quantity_on_hand > 200
    GROUP BY inv_item_sk, inv_date_sk
),
promo_active AS (
    SELECT p_item_sk,
           p_start_date_sk,
           p_end_date_sk,
           p_cost,
           p_discount_active,
           p_promo_name,
           p_response_target,
           p_channel_email,
           p_channel_tv,
           p_purpose
    FROM promotion
    WHERE p_discount_active = 'Y'
),
web_page_stats AS (
    SELECT wp_web_page_sk,
           wp_type,
           wp_creation_date_sk,
           wp_access_date_sk,
           wp_link_count,
           wp_image_count,
           wp_char_count,
           wp_max_ad_count
    FROM web_page
    WHERE wp_type IN ('Landing', 'Product')
),
joined_data AS (
    SELECT d.hd_income_band_sk,
           d.hd_vehicle_count,
           i.inv_item_sk,
           i.inv_date_sk,
           p.p_promo_name,
           i.total_quantity,
           p.p_cost,
           w.wp_web_page_sk,
           w.wp_link_count,
           w.wp_image_count
    FROM inv_agg i
    JOIN promo_active p
      ON i.inv_item_sk = p.p_item_sk
     AND i.inv_date_sk = p.p_start_date_sk
    JOIN web_page_stats w
      ON p.p_start_date_sk = w.wp_creation_date_sk
    JOIN household_demographics d
      ON 1 = 1
    WHERE d.hd_income_band_sk IN (2, 3, 4)
      AND d.hd_vehicle_count <= 2
),
aggregated AS (
    SELECT hd_income_band_sk,
           hd_vehicle_count,
           inv_item_sk,
           inv_date_sk,
           p_promo_name,
           SUM(total_quantity) AS total_inventory_qty,
           AVG(p_cost) AS avg_promo_cost,
           COUNT(DISTINCT wp_web_page_sk) AS distinct_pages,
           SUM(wp_link_count) AS total_links,
           SUM(wp_image_count) AS total_images
    FROM joined_data
    GROUP BY hd_income_band_sk,
             hd_vehicle_count,
             inv_item_sk,
             inv_date_sk,
             p_promo_name
    HAVING SUM(total_quantity) > 500
)
SELECT hd_income_band_sk,
       hd_vehicle_count,
       inv_item_sk,
       inv_date_sk,
       p_promo_name,
       total_inventory_qty,
       avg_promo_cost,
       distinct_pages,
       total_links,
       total_images,
       ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_inventory_qty DESC) AS rank_by_inventory
FROM aggregated
ORDER BY total_inventory_qty DESC
LIMIT 100
