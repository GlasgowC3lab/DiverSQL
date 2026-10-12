WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_department,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id, cp.cp_catalog_page_number, cp.cp_department
)
SELECT
    cp_catalog_page_id,
    cp_catalog_page_number,
    cp_department,
    total_net_paid,
    total_net_profit,
    CASE
        WHEN total_net_paid = 0 THEN 0
        ELSE total_net_profit / total_net_paid
    END AS profit_margin,
    CASE
        WHEN total_net_paid = 0 THEN 'No Sales'
        WHEN total_net_profit / total_net_paid < 0.1 THEN 'Low'
        WHEN total_net_profit / total_net_paid < 0.3 THEN 'Medium'
        ELSE 'High'
    END AS margin_category,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY CASE WHEN total_net_paid = 0 THEN 0 ELSE total_net_profit / total_net_paid END DESC) AS margin_rank
FROM page_sales
ORDER BY revenue_rank
LIMIT 10
