WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_discount_amt,
        cs.cs_wholesale_cost,
        cs.cs_ext_wholesale_cost,
        cs.cs_net_paid,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_ext_discount_amt > 1000
        AND cs.cs_wholesale_cost BETWEEN 20 AND 50
        AND cd.cd_gender = 'M'
        AND cd.cd_education_status = 'College'
        AND cd.cd_purchase_estimate >= 5000
        AND cd.cd_dep_count <= 2
        AND cs.cs_order_number NOT IN (
            SELECT cs_order_number
            FROM catalog_sales
            WHERE cs_ext_discount_amt > 5000
        )
)
SELECT
    cs_order_number,
    COUNT(*) AS order_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(cs_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(cs_wholesale_cost) AS max_wholesale_price
FROM filtered_sales
GROUP BY cs_order_number
ORDER BY total_net_paid DESC
LIMIT 100
