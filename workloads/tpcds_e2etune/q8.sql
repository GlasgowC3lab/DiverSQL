WITH sales_combined AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           hd.hd_vehicle_count AS vehicle_count,
           CASE
               WHEN p.p_channel_email = 'Y' THEN 'Email'
               WHEN p.p_channel_tv = 'Y' THEN 'TV'
               WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
               ELSE 'Other'
           END AS promo_channel,
           'catalog' AS source
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    UNION ALL
    SELECT ss.ss_item_sk AS item_sk,
           ss.ss_net_profit AS net_profit,
           hd.hd_vehicle_count AS vehicle_count,
           CASE
               WHEN p.p_channel_email = 'Y' THEN 'Email'
               WHEN p.p_channel_tv = 'Y' THEN 'TV'
               WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
               ELSE 'Other'
           END AS promo_channel,
           'store' AS source
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
)
SELECT i.i_item_id,
       i.i_product_name,
       SUM(s.net_profit) AS total_net_profit,
       SUM(CASE WHEN s.source = 'catalog' THEN s.net_profit ELSE 0 END) AS catalog_net_profit,
       SUM(CASE WHEN s.source = 'store' THEN s.net_profit ELSE 0 END) AS store_net_profit,
       MAX(s.promo_channel) AS primary_promo_channel,
       s.vehicle_count
FROM sales_combined s
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY i.i_item_id, i.i_product_name, s.vehicle_count
HAVING SUM(s.net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 5
