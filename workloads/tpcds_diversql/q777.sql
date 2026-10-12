WITH sampled_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_ext_wholesale_cost,
            cs.cs_quantity,
            cs.cs_warehouse_sk,
            cs.cs_call_center_sk
        FROM catalog_sales cs
        TABLESAMPLE BERNOULLI (10)
        WHERE cs.cs_ext_wholesale_cost > 2000
    ),
    sales_enriched AS (
        SELECT
            s.cs_order_number,
            s.cs_sold_date_sk,
            s.cs_ext_wholesale_cost,
            s.cs_quantity,
            w.w_warehouse_name,
            cc.cc_name
        FROM sampled_sales s
        JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
        WHERE w.w_warehouse_sq_ft > 500000
    ),
    store_ret AS (
        SELECT DISTINCT
            sr.sr_ticket_number      AS order_number,
            sr.sr_returned_date_sk   AS returned_date_sk,
            sr.sr_return_quantity    AS return_quantity,
            st.s_store_name,
            r.r_reason_desc
        FROM store_returns sr
        JOIN store st ON sr.sr_store_sk = st.s_store_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_return_quantity > 1
          AND st.s_division_name = 'Unknown'
    ),
    sales_keys AS (
        SELECT cs_order_number AS order_key, cs_sold_date_sk AS date_key
        FROM sales_enriched
    ),
    store_keys AS (
        SELECT order_number AS order_key, returned_date_sk AS date_key
        FROM store_ret
    ),
    sales_minus_store AS (
        SELECT order_key, date_key
        FROM sales_keys
        EXCEPT
        SELECT order_key, date_key
        FROM store_keys
    )
SELECT
    sm.order_key,
    sm.date_key,
    se.w_warehouse_name,
    se.cc_name,
    cr_sum.total_return_amount
FROM sales_minus_store sm
JOIN sales_enriched se
    ON sm.order_key = se.cs_order_number
   AND sm.date_key = se.cs_sold_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_order_number = sm.order_key
) cr_sum
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr_chk
    WHERE cr_chk.cr_order_number = sm.order_key
)
ORDER BY cr_sum.total_return_amount DESC NULLS LAST
LIMIT 100
