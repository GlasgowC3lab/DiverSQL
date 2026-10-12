WITH bill_sales AS (
    SELECT
        cs.cs_order_number,
        cust.c_customer_id,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
        ON cust.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cust.c_birth_month = 5
        AND cd.cd_marital_status = 'M'
    GROUP BY cs.cs_order_number, cust.c_customer_id
),
ship_sales AS (
    SELECT
        cs.cs_order_number,
        cust.c_customer_id AS c_customer_id,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN customer cust
        ON cs.cs_ship_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count > 3
        AND cs.cs_ship_hdemo_sk = 1257
    GROUP BY cs.cs_order_number, cust.c_customer_id
),
combined AS (
    SELECT cs_order_number, c_customer_id, total_paid, order_cnt FROM bill_sales
    UNION ALL
    SELECT cs_order_number, c_customer_id, total_paid, order_cnt FROM ship_sales
)
SELECT cs_order_number, c_customer_id, total_paid, order_cnt
FROM combined
WHERE cs_order_number NOT IN (
    SELECT cs_order_number FROM catalog_sales WHERE cs_quantity = 0
)
ORDER BY total_paid DESC
LIMIT 100
