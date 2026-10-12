WITH page_sales_a AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
        lc.sale_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS sale_cnt
        FROM catalog_sales cs_l
        WHERE cs_l.cs_catalog_page_sk = cp.cp_catalog_page_sk
    ) lc
    WHERE cp.cp_catalog_number IN (1, 4, 7)
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_number, lc.sale_cnt
),
page_sales_b AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
        lc.sale_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS sale_cnt
        FROM catalog_sales cs_l
        WHERE cs_l.cs_catalog_page_sk = cp.cp_catalog_page_sk
    ) lc
    WHERE cp.cp_catalog_number IN (16, 18)
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_number, lc.sale_cnt
)
SELECT *
FROM page_sales_a
EXCEPT
SELECT *
FROM page_sales_b
ORDER BY total_net_profit DESC
LIMIT 100
