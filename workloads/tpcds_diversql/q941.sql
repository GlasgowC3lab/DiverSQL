WITH catalog_ret_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_amount) AS total_catalog_return,
        COUNT(DISTINCT cr_order_number) AS catalog_orders
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ca.ca_city,
    d_return.d_year,
    s.s_store_name,
    wp.wp_url,
    cr.total_catalog_return,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(DISTINCT wr.wr_return_amt) AS distinct_web_return_sum,
    COUNT(DISTINCT cr_detail.cr_return_quantity) AS distinct_catalog_return_qty,
    SUM(u.val) AS sum_unnested_vals
FROM catalog_ret_agg cr
JOIN catalog_returns cr_detail
    ON cr_detail.cr_item_sk = cr.cr_item_sk
JOIN item i
    ON i.i_item_sk = cr_detail.cr_item_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cr_detail.cr_refunded_addr_sk
JOIN date_dim d_return
    ON d_return.d_date_sk = cr_detail.cr_returned_date_sk
FULL OUTER JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
LEFT JOIN date_dim d_access
    ON d_access.d_date_sk = wp.wp_access_date_sk
LEFT JOIN date_dim d_creation
    ON d_creation.d_date_sk = wp.wp_creation_date_sk
JOIN customer cust_returning
    ON cust_returning.c_customer_sk = cr_detail.cr_returning_customer_sk
JOIN customer_address ca_wr_refund
    ON ca_wr_refund.ca_address_sk = wr.wr_refunded_addr_sk
CROSS JOIN LATERAL (
    SELECT ARRAY[wr.wr_return_amt, wr.wr_fee] AS vals
) AS t
CROSS JOIN UNNEST(t.vals) AS u(val)
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = i.i_item_sk
      AND wr2.wr_returned_date_sk = d_return.d_date_sk
)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    ca.ca_city,
    d_return.d_year,
    s.s_store_name,
    wp.wp_url,
    cr.total_catalog_return
ORDER BY cr.total_catalog_return DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
