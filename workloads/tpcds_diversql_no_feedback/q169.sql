WITH customers_sales AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2021
      AND regexp_like(c.c_email_address, '[A-Z0-9._%+-]+@example\\.com')
      AND c.c_birth_country = 'MEXICO'
),
customers_returns AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
      AND regexp_like(r.r_reason_desc, '.*size.*')
      AND cr.cr_return_amount > 0
),
intersected_customers AS (
    SELECT c_customer_sk FROM customers_sales
    INTERSECT
    SELECT c_customer_sk FROM customers_returns
)
SELECT
    ca.ca_state AS state,
    d.d_year AS year,
    concat('State: ', ca.ca_state) AS state_label,
    MIN(regexp_extract(c.c_email_address, '@(.*)$', 1)) AS email_domain,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders
FROM intersected_customers ic
JOIN customer c               ON ic.c_customer_sk = c.c_customer_sk
JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales ss           ON c.c_customer_sk = ss.ss_customer_sk
JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY GROUPING SETS (
    (ca.ca_state, d.d_year),
    (ca.ca_state),
    ()
)
ORDER BY total_net_paid DESC, state
