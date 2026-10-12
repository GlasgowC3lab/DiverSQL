WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        i.i_item_id,
        i.i_item_desc,
        c.c_customer_id,
        c.c_first_name,
        ca.ca_state
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_description LIKE '%Holiday%'
      AND regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{2}')
)
SELECT
    s.c_customer_id               AS customer_id,
    s.ca_state                    AS state,
    substring(s.c_first_name, 1, 1) AS first_initial,
    regexp_extract(s.i_item_id, '^(.{6})', 1) AS item_prefix,
    SUM(s.cs_net_paid_inc_ship)   AS total_net_paid
FROM sales_filtered s
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = s.cs_order_number
      AND wr.wr_item_sk = s.cs_item_sk
)
GROUP BY
    s.c_customer_id,
    s.ca_state,
    substring(s.c_first_name, 1, 1),
    regexp_extract(s.i_item_id, '^(.{6})', 1)
ORDER BY total_net_paid DESC
LIMIT 100
