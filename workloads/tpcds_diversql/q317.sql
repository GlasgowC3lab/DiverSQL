WITH
    scalar_val AS (
        SELECT AVG(cs_net_paid) AS avg_paid
        FROM catalog_sales
        WHERE cs_ship_mode_sk = 1
    ),
    sub_a AS (
        SELECT DISTINCT
            cs.cs_order_number,
            cs.cs_item_sk,
            cs.cs_net_paid,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_net_paid DESC) AS rn
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        CROSS JOIN UNNEST(ARRAY[cs.cs_quantity, cs.cs_ext_sales_price]) AS t(val)
        WHERE sm.sm_carrier = 'UPS'
          AND cs.cs_net_paid > (SELECT avg_paid FROM scalar_val)
    ),
    sub_b AS (
        SELECT DISTINCT
            cs.cs_order_number,
            cs.cs_item_sk,
            cs.cs_net_paid,
            ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS rn
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE cp.cp_department = 'Electronics'
          AND ca.ca_zip LIKE '5%'
    )
SELECT
    order_number,
    item_sk,
    net_paid,
    rn
FROM (
    SELECT
        cs_order_number AS order_number,
        cs_item_sk AS item_sk,
        cs_net_paid AS net_paid,
        rn
    FROM sub_a
    INTERSECT
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_net_paid,
        rn
    FROM sub_b
) t
ORDER BY net_paid DESC
LIMIT 100
