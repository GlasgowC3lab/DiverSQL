WITH sales_union AS (
    SELECT ss_item_sk AS item_sk,
           'store' AS channel,
           ss_net_profit AS net_profit,
           ss_quantity AS qty,
           ss_sold_date_sk AS date_sk
    FROM store_sales
    UNION ALL
    SELECT cs_item_sk,
           'catalog',
           cs_net_profit,
           cs_quantity,
           cs_sold_date_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_item_sk,
           'web',
           ws_net_profit,
           ws_quantity,
           ws_sold_date_sk
    FROM web_sales
),
sales_by_item AS (
    SELECT su.item_sk,
           SUM(su.net_profit) AS total_net_profit,
           SUM(su.qty) AS total_qty,
           MAX(d.d_date) AS latest_sale_date,
           COUNT(DISTINCT su.channel) AS channels_sold,
           array_join(array_agg(su.channel ORDER BY su.channel), ',') AS channels_list
    FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    GROUP BY su.item_sk
),
promo_info AS (
    SELECT p.p_item_sk,
           p.p_promo_id,
           p.p_start_date_sk,
           p.p_end_date_sk,
           p.p_discount_active,
           ROW_NUMBER() OVER (PARTITION BY p.p_item_sk ORDER BY p.p_start_date_sk DESC) AS rn
    FROM promotion p
),
latest_promo AS (
    SELECT pi.p_item_sk,
           pi.p_promo_id,
           pi.p_start_date_sk,
           pi.p_end_date_sk,
           pi.p_discount_active
    FROM promo_info pi
    WHERE pi.rn = 1
),
items_in_all_channels AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    INTERSECT
    SELECT cs_item_sk FROM catalog_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
),
selected_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_brand,
           i.i_category,
           i.i_class,
           ia.total_net_profit,
           ia.total_qty,
           ia.latest_sale_date,
           ia.channels_sold,
           ia.channels_list,
           lp.p_promo_id,
           lp.p_discount_active
    FROM item i
    LEFT JOIN sales_by_item ia ON i.i_item_sk = ia.item_sk
    LEFT JOIN latest_promo lp ON i.i_item_sk = lp.p_item_sk
    WHERE i.i_item_sk IN (SELECT item_sk FROM items_in_all_channels)
      AND (i.i_class = 'Electronics' OR i.i_class IS NULL)
)
SELECT 
    si.i_item_id,
    si.i_product_name,
    si.i_brand,
    si.i_category,
    COALESCE(si.p_promo_id, 'NO_PROMO') AS promo_id,
    si.total_net_profit,
    si.total_qty,
    si.latest_sale_date,
    si.channels_sold,
    si.channels_list,
    CASE 
        WHEN si.total_net_profit > 100000 THEN 'HIGH'
        WHEN si.total_net_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_bracket,
    ROW_NUMBER() OVER (PARTITION BY si.i_category ORDER BY si.total_net_profit DESC) AS category_rank,
    (SELECT AVG(inner_ia.total_net_profit)
     FROM sales_by_item inner_ia
     JOIN item inner_i ON inner_ia.item_sk = inner_i.i_item_sk
     WHERE inner_i.i_brand = si.i_brand) AS brand_avg_profit,
    CONCAT(si.i_brand, ' - ', si.i_category) AS brand_category,
    CASE WHEN si.latest_sale_date IS NULL THEN TRUE ELSE FALSE END AS no_recent_sales,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM store_sales ss
            WHERE ss.ss_item_sk = si.i_item_sk
              AND ss.ss_quantity > 10
              AND ss.ss_net_paid > 1000
        )
        OR NOT EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_item_sk = si.i_item_sk
        ) THEN 'QUALIFIED'
        ELSE 'EXCLUDED'
    END AS qualification_flag
FROM selected_items si
ORDER BY si.total_net_profit DESC NULLS LAST
LIMIT 100
