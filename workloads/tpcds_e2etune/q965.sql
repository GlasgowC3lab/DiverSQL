WITH agg AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_number AS catalog_number,
        r.r_reason_desc AS reason_desc,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        (SUM(cr.cr_return_quantity) * 1.0 / NULLIF(SUM(cs.cs_quantity), 0)) AS return_rate,
        (SUM(cs.cs_net_paid_inc_tax) - SUM(cr.cr_return_amount)) AS net_revenue
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_catalog_page_number IN (2, 3)
      AND cp.cp_description LIKE '%public%'
    GROUP BY cp.cp_department, cp.cp_catalog_number, r.r_reason_desc
    HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
)
SELECT
    department,
    catalog_number,
    reason_desc,
    total_sales,
    total_return_amount,
    total_quantity_sold,
    total_quantity_returned,
    return_rate,
    net_revenue,
    RANK() OVER (ORDER BY net_revenue DESC) AS revenue_rank
FROM agg
ORDER BY net_revenue DESC
LIMIT 100
