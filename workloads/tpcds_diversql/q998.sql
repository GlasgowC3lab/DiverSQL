WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
store_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
),
joined_catalog AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cp.cp_department,
        cp.cp_type,
        ca.ca_state,
        ca.ca_country,
        cs.cs_call_center_sk,
        cs.cs_ext_tax
    FROM cs_sample cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cs.cs_call_center_sk IN (13, 31, 34, 10)
      AND cs.cs_ext_tax > 50
      AND ca.ca_country = 'United States'
),
joined_store AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        ss.ss_quantity,
        ss.ss_list_price,
        ca2.ca_state AS store_state,
        ca2.ca_country AS store_country,
        ss.ss_wholesale_cost
    FROM store_sample ss
    JOIN customer_address ca2
        ON ss.ss_addr_sk = ca2.ca_address_sk
    WHERE ss.ss_list_price > 20
      AND ss.ss_quantity >= 1
      AND ca2.ca_state = 'CA'
      AND ss.ss_ext_tax IS NOT NULL
),
combined AS (
    SELECT
        jc.cs_order_number               AS order_id,
        jc.cs_net_paid                   AS net_paid,
        jc.cp_department                 AS department,
        jc.cp_type                       AS catalog_type,
        jc.ca_state                      AS bill_state,
        NULL                             AS ticket_number,
        NULL                             AS store_state,
        CASE
            WHEN jc.cs_net_paid > 1000 THEN 'HIGH'
            WHEN jc.cs_net_paid > 500  THEN 'MEDIUM'
            ELSE 'LOW'
        END                              AS revenue_bucket
    FROM joined_catalog jc
    FULL OUTER JOIN joined_store js
        ON jc.cs_order_number = js.ss_ticket_number
),
ranked AS (
    SELECT
        order_id,
        net_paid,
        department,
        catalog_type,
        bill_state,
        ticket_number,
        store_state,
        revenue_bucket,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY net_paid DESC) AS rn_dept,
        RANK()        OVER (ORDER BY net_paid DESC)                AS overall_rank
    FROM combined
    WHERE net_paid IS NOT NULL
)
SELECT
    order_id,
    net_paid,
    department,
    catalog_type,
    bill_state,
    ticket_number,
    store_state,
    revenue_bucket,
    overall_rank
FROM ranked
WHERE rn_dept <= 10

UNION DISTINCT

SELECT
    order_id,
    net_paid,
    department,
    catalog_type,
    bill_state,
    ticket_number,
    store_state,
    revenue_bucket,
    overall_rank
FROM ranked
WHERE revenue_bucket = 'HIGH' AND overall_rank <= 50

ORDER BY overall_rank
LIMIT 100
