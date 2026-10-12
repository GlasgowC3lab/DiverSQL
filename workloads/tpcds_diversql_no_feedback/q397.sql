WITH ss_agg AS (
    SELECT ss_customer_sk,
           sum(ss_net_paid) AS total_net_paid,
           sum(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2459000
    GROUP BY ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_gmt_offset,
    cc.cc_name,
    cc.cc_state,
    w.w_city AS warehouse_city,
    w.w_zip,
    cp.cp_type,
    cr.cr_return_tax,
    wp.wp_type,
    ss_agg.total_net_paid,
    ss_agg.total_quantity,
    (
        SELECT max(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
    ) AS max_return_amt_warehouse,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY ss_agg.total_net_paid DESC) AS state_rank
FROM ss_agg
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    w.w_zip = '46098'
    AND cc.cc_state = 'CA'
    AND cp.cp_type = 'PROMO'
    AND cr.cr_return_tax > 20
    AND wp.wp_type = 'HOME'
    AND ca.ca_gmt_offset = -5.00
LIMIT 100
