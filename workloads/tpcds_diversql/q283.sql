WITH sales AS (
    SELECT
        d.d_year,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        SUM(ss.ss_ext_discount_amt) AS metric_amount,
        COUNT(*) AS metric_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT concat(ca.ca_street_number, ' ', ca.ca_street_name) AS full_addr
    ) AS addr
    WHERE regexp_like(p.p_promo_name, '^Spring.*202[0-9]$')
      AND c.c_email_address LIKE '%@example.com'
      AND ca.ca_location_type = 'apartment'
      AND addr.full_addr LIKE '%Main%'
    GROUP BY d.d_year, regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)
),
returns AS (
    SELECT
        d.d_year,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        SUM(wr.wr_net_loss) AS metric_amount,
        COUNT(*) AS metric_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT concat(ca.ca_street_number, ' ', ca.ca_street_name) AS full_addr
    ) AS addr
    WHERE wr.wr_return_quantity > 0
      AND c.c_email_address LIKE '%@example.com'
      AND ca.ca_location_type = 'apartment'
      AND addr.full_addr LIKE '%Main%'
    GROUP BY d.d_year, regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)
)
SELECT
    u.d_year,
    u.email_domain,
    SUM(u.metric_amount) AS total_amount,
    SUM(u.metric_cnt) AS total_transactions,
    COUNT(DISTINCT u.source) AS source_count
FROM (
    SELECT d_year, email_domain, metric_amount, metric_cnt, 'sales' AS source FROM sales
    UNION
    SELECT d_year, email_domain, metric_amount, metric_cnt, 'returns' AS source FROM returns
) u
GROUP BY u.d_year, u.email_domain
ORDER BY total_amount DESC
LIMIT 10
