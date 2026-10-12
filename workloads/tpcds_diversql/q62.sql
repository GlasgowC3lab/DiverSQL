WITH filtered_customer AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_day, c_birth_month
    FROM tpcds.customer
    WHERE c_customer_sk IN (
        SELECT wr_refunded_customer_sk
        FROM tpcds.web_returns
        WHERE wr_fee > 20
    )
    AND c_birth_day BETWEEN 1 AND 15
    AND c_birth_month IN (1, 3, 5)
)
SELECT
    i.i_brand_id,
    i.i_category,
    CASE
        WHEN r.r_reason_desc = 'Customer not satisfied' THEN 'Dissatisfied'
        WHEN r.r_reason_desc = 'Product defect' THEN 'Defect'
        ELSE 'Other'
    END AS reason_group,
    COUNT(DISTINCT wr.wr_order_number) AS orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_fee) AS avg_fee,
    MIN(wr.wr_return_quantity) AS min_quantity,
    MAX(wr.wr_return_quantity) AS max_quantity
FROM tpcds.web_returns wr
FULL OUTER JOIN tpcds.item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN filtered_customer fc
    ON wr.wr_refunded_customer_sk = fc.c_customer_sk
JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    i.i_brand_id IN (1001001, 2004001)
    AND i.i_container = 'Unknown'
    AND i.i_product_name LIKE '%able%'
    AND r.r_reason_id IN ('R001', 'R002')
    AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
GROUP BY
    i.i_brand_id,
    i.i_category,
    CASE
        WHEN r.r_reason_desc = 'Customer not satisfied' THEN 'Dissatisfied'
        WHEN r.r_reason_desc = 'Product defect' THEN 'Defect'
        ELSE 'Other'
    END
ORDER BY total_return_amount DESC
LIMIT 100
