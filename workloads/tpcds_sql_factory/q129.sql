SELECT
    t.cp_department,
    t.cp_catalog_page_id,
    t.cp_catalog_page_number,
    t.cp_type,
    t.total_net_paid,
    t.total_discount,
    t.total_quantity,
    t.discount_category,
    RANK() OVER (PARTITION BY t.cp_department ORDER BY t.total_net_paid DESC) AS dept_rank
FROM (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE
            WHEN SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) > 0.15 THEN 'High Discount'
            ELSE 'Standard Discount'
        END AS discount_category
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cp.cp_department,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_type
) t
WHERE t.total_net_paid > 1000
ORDER BY t.cp_department, dept_rank
