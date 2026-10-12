WITH
    returns AS (
        SELECT DISTINCT
            c.c_customer_id,
            c.c_customer_sk
        FROM catalog_returns cr
        INNER JOIN customer c
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
        INNER JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    web AS (
        SELECT DISTINCT
            c.c_customer_id,
            c.c_customer_sk
        FROM web_sales ws
        INNER JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        INNER JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    union_set AS (
        SELECT c_customer_id FROM returns
        UNION
        SELECT c_customer_id FROM web
    ),
    intersect_set AS (
        SELECT c_customer_id FROM returns
        INTERSECT
        SELECT c_customer_id FROM web
    ),
    full_join AS (
        SELECT
            r.c_customer_id AS return_customer_id,
            w.c_customer_id AS web_customer_id
        FROM returns r
        FULL OUTER JOIN web w
            ON r.c_customer_id = w.c_customer_id
    )
SELECT c_customer_id
FROM union_set
EXCEPT
SELECT c_customer_id
FROM intersect_set
ORDER BY c_customer_id
LIMIT 100
