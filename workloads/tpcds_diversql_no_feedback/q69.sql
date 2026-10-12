WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_sold_date_sk,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_email_address
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_email_address LIKE '%@%.com'
      AND REGEXP_LIKE(c.c_email_address, '@[A-Za-z0-9._%+-]+\\.com$')
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
          WHERE cr.cr_order_number = cs.cs_order_number
            AND REGEXP_LIKE(r.r_reason_desc, 'damaged')
      )
)
SELECT
    CONCAT('Cust_', fs.c_customer_id) AS cust_label,
    fs.c_email_address,
    REGEXP_EXTRACT(fs.c_email_address, '@(.+)$') AS email_domain,
    SUM(fs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS orders
FROM filtered_sales fs
GROUP BY
    CONCAT('Cust_', fs.c_customer_id),
    fs.c_email_address,
    REGEXP_EXTRACT(fs.c_email_address, '@(.+)$')
ORDER BY total_net_paid DESC
LIMIT 100
