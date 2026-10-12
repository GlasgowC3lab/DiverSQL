WITH intersected_customers AS (
    SELECT cr_returning_customer_sk AS cust_sk FROM tpcds.catalog_returns
    INTERSECT
    SELECT c.c_customer_sk FROM tpcds.customer c
    JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)$') AS last_word,
    CASE
        WHEN REGEXP_LIKE(r.r_reason_desc, '(?i)fraud') THEN 'Potential Fraud'
        ELSE 'Other'
    END AS reason_category,
    (SELECT AVG(cr2.cr_return_amount) FROM tpcds.catalog_returns cr2) AS avg_return_amount_overall
FROM tpcds.catalog_returns cr
FULL OUTER JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    (r.r_reason_id LIKE 'R%' OR r.r_reason_id IS NULL)
    AND cr.cr_returning_customer_sk IN (SELECT cust_sk FROM intersected_customers)
    AND cr.cr_returning_customer_sk IN (
        SELECT c.c_customer_sk FROM tpcds.customer c WHERE c.c_birth_year = 1975
    )
    AND REGEXP_LIKE(r.r_reason_desc, '(?i)damage|lost|fraud')
GROUP BY
    r.r_reason_id,
    r.r_reason_desc,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)$'),
    CASE
        WHEN REGEXP_LIKE(r.r_reason_desc, '(?i)fraud') THEN 'Potential Fraud'
        ELSE 'Other'
    END
ORDER BY total_return_amount DESC
LIMIT 100
