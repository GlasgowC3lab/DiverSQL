WITH orders_without_store_return AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT sr.sr_ticket_number
    FROM store_returns sr
),
filtered AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        i.i_brand,
        i.i_category,
        w.w_city,
        r.r_reason_desc,
        cs.cs_net_paid,
        cr.cr_return_amount,
        wr.wr_account_credit,
        cs.cs_order_number
    FROM call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN customer c
        ON c.c_customer_sk = sr.sr_customer_sk
    RIGHT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
       AND wr.wr_item_sk = i.i_item_sk
    JOIN orders_without_store_return ow
        ON ow.cs_order_number = cs.cs_order_number
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND w.w_city = 'Seattle'
      AND r.r_reason_desc = 'Damaged'
      AND wp.wp_image_count >= 3
)
SELECT
    cc_name,
    cc_state,
    i_brand,
    i_category,
    w_city,
    r_reason_desc,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(wr_account_credit) AS avg_account_credit
FROM filtered
GROUP BY
    cc_name,
    cc_state,
    i_brand,
    i_category,
    w_city,
    r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
