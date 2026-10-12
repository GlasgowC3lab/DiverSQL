WITH sales_pages AS (
    SELECT cp.cp_catalog_page_id AS page_id
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_type = 'monthly'
      AND p.p_channel_radio = 'N'
      AND cs.cs_net_profit > 0
    GROUP BY cp.cp_catalog_page_id
),
return_pages AS (
    SELECT cp.cp_catalog_page_id AS page_id
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_catalog_page_id
),
pages_without_returns AS (
    SELECT page_id FROM sales_pages
    EXCEPT
    SELECT page_id FROM return_pages
),
sales_agg AS (
    SELECT cp.cp_catalog_page_id AS page_id,
           SUM(cs.cs_net_profit) AS total_profit,
           MAX(cp.cp_description) AS description,
           MAX(cp.cp_department) AS department
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_type = 'monthly'
      AND p.p_channel_radio = 'N'
      AND cs.cs_net_profit > 0
    GROUP BY cp.cp_catalog_page_id
)
SELECT
    sa.page_id,
    sa.description,
    sa.department,
    sa.total_profit
FROM pages_without_returns pwr
JOIN sales_agg sa ON pwr.page_id = sa.page_id
ORDER BY sa.total_profit DESC
LIMIT 100
