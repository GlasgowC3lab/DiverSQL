WITH catalog_totals AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS total_sales,
        CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'large'
    GROUP BY i.i_item_id, i.i_product_name
),
web_totals AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_paid) AS total_sales,
        CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_quantity > 5
      AND p.p_discount_active = 'Y'
      AND EXISTS (SELECT 1 FROM tpcds.store s WHERE s.s_country = 'United States')
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM (SELECT * FROM catalog_totals)
EXCEPT
SELECT * FROM web_totals
ORDER BY total_sales DESC, i_item_id
OFFSET 0
LIMIT 100
