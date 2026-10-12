WITH filtered_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT customer_id, return_amount
FROM (
    SELECT c.c_customer_id AS customer_id,
           sr.sr_return_amt AS return_amount
    FROM store_returns sr
    JOIN filtered_dates fd ON sr.sr_returned_date_sk = fd.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
)
INTERSECT
SELECT customer_id, return_amount
FROM (
    SELECT c.c_customer_id AS customer_id,
           cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN filtered_dates fd ON cr.cr_returned_date_sk = fd.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_state = 'CA'
)
ORDER BY customer_id,
         return_amount
LIMIT 100
