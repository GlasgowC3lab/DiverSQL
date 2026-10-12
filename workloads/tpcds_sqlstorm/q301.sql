WITH recent_promos AS (
    SELECT p.p_item_sk AS p_item_sk,
           max_by(p.p_promo_name, p.p_start_date_sk) AS latest_promo_name,
           max(p.p_start_date_sk) AS latest_start_date_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_item_sk
),
sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog_sales' AS channel,
           cs.cs_call_center_sk AS call_center_sk,
           cs.cs_catalog_page_sk AS catalog_page_sk,
           cs.cs_ship_mode_sk AS ship_mode_sk,
           cs.cs_warehouse_sk AS warehouse_sk,
           cs.cs_order_number AS order_number,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs

    UNION ALL

    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store_sales' AS channel,
           NULL AS call_center_sk,
           NULL AS catalog_page_sk,
           NULL AS ship_mode_sk,
           NULL AS warehouse_sk,
           ss.ss_ticket_number AS order_number,
           ss.ss_promo_sk AS promo_sk
    FROM store_sales ss

    UNION ALL

    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web_sales' AS channel,
           NULL AS call_center_sk,
           ws.ws_web_page_sk AS catalog_page_sk,
           ws.ws_ship_mode_sk AS ship_mode_sk,
           ws.ws_warehouse_sk AS warehouse_sk,
           ws.ws_order_number AS order_number,
           ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
),
ranked_sales AS (
    SELECT su.*,
           ROW_NUMBER() OVER (PARTITION BY su.item_sk ORDER BY su.sold_date_sk DESC) AS rn,
           CASE
               WHEN su.net_profit > 0 THEN 'POSITIVE'
               WHEN su.net_profit < 0 THEN 'NEGATIVE'
               ELSE 'ZERO'
           END AS profit_flag
    FROM sales_union su
),
filtered_sales AS (
    SELECT rs.*
    FROM ranked_sales rs
    WHERE rs.rn = 1
      AND (rs.quantity > 0 OR rs.quantity IS NULL)
      AND (rs.net_paid BETWEEN 0 AND 1000000 OR rs.net_paid IS NULL)
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = rs.order_number
            AND cr.cr_return_quantity > 0
      )
),
joined AS (
    SELECT fs.*,
           COALESCE(cc.cc_name, 'UNKNOWN') AS call_center_name,
           COALESCE(cp.cp_description, 'N/A') AS catalog_page_desc,
           rp.latest_promo_name,
           CASE WHEN fs.channel = 'web_sales' THEN 'WEB_' || COALESCE(wp.wp_type, 'UNKNOWN') ELSE 'NON_WEB' END AS source_flag,
           (fs.net_paid * 1.08) - (fs.net_paid * 0.02) AS projected_net_paid,
           NULLIF(fs.net_profit, 0) AS net_profit_nonzero,
           CONCAT_WS(' - ', COALESCE(i.i_brand, ''), COALESCE(i.i_category, ''), COALESCE(i.i_product_name, '')) AS item_full_desc
    FROM filtered_sales fs
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = fs.call_center_sk
    LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = fs.catalog_page_sk
    LEFT JOIN recent_promos rp ON rp.p_item_sk = fs.item_sk
    LEFT JOIN item i ON i.i_item_sk = fs.item_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = fs.catalog_page_sk
    WHERE ((fs.profit_flag = 'POSITIVE' AND fs.net_paid > 1000)
       OR (fs.profit_flag = 'NEGATIVE' AND fs.net_paid < 100)
       OR (fs.profit_flag = 'ZERO' AND fs.net_paid IS NULL))
       AND (fs.call_center_sk IS NOT NULL OR fs.catalog_page_sk IS NOT NULL)
),
agg AS (
    SELECT
        call_center_name,
        catalog_page_desc,
        profit_flag,
        source_flag,
        COUNT(*) AS sales_cnt,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(projected_net_paid) AS total_projected_net_paid,
        AVG(net_profit_nonzero) AS avg_net_profit,
        MAX(CASE WHEN length(item_full_desc) > 0 THEN item_full_desc END) AS exemplar_item_desc,
        MIN(CASE WHEN cc_meta.cc_gmt_offset IS NOT NULL THEN cc_meta.cc_gmt_offset ELSE -999 END) AS min_gmt_offset,
        MAX(CASE WHEN cc_meta.cc_tax_percentage IS NOT NULL THEN cc_meta.cc_tax_percentage ELSE 0 END) AS max_tax_percentage
    FROM joined
    LEFT JOIN (SELECT DISTINCT cc_call_center_sk, cc_gmt_offset, cc_tax_percentage FROM call_center) cc_meta
        ON cc_meta.cc_call_center_sk = joined.call_center_sk
    GROUP BY ROLLUP (call_center_name, catalog_page_desc, profit_flag, source_flag)
)
SELECT *
FROM agg
WHERE (sales_cnt > 10 OR sales_cnt IS NULL)
  AND (total_net_paid IS NOT NULL AND total_net_paid > 0)
  AND (exemplar_item_desc IS NOT NULL)
  AND ( (call_center_name LIKE '%Center%' AND source_flag = 'NON_WEB')
        OR (catalog_page_desc LIKE '%Special%' AND source_flag LIKE 'WEB_%')
        OR (call_center_name IS NULL AND source_flag LIKE 'WEB_%') )
  AND (coalesce(min_gmt_offset, -999) <> -999)
ORDER BY total_projected_net_paid DESC NULLS LAST
LIMIT 100
