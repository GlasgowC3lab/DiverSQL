WITH sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_amount,
        ARRAY[c.c_preferred_cust_flag, c.c_salutation] AS attrs
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_coupon_amt > 500
    GROUP BY c.c_customer_id, c.c_preferred_cust_flag, c.c_salutation
),
sales_unnest AS (
    SELECT
        'store' AS source,
        s.c_customer_id,
        s.total_amount,
        a AS attribute
    FROM sales s
    CROSS JOIN UNNEST(s.attrs) AS t(a)
),
returns AS (
    SELECT
        c.c_customer_id,
        SUM(wr.wr_return_amt) AS total_amount,
        MAP(ARRAY['type', 'autogen'], ARRAY[wp.wp_type, wp.wp_autogen_flag]) AS attrs
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'feedback'
    GROUP BY c.c_customer_id, wp.wp_type, wp.wp_autogen_flag
),
returns_unnest AS (
    SELECT
        'web_return' AS source,
        r.c_customer_id,
        r.total_amount,
        k AS attr_key,
        v AS attr_value
    FROM returns r
    CROSS JOIN UNNEST(r.attrs) AS t(k, v)
),
returns_flat AS (
    SELECT
        source,
        c_customer_id,
        total_amount,
        CONCAT(attr_key, '=', attr_value) AS attribute
    FROM returns_unnest
)
SELECT
    source,
    c_customer_id,
    total_amount,
    attribute
FROM sales_unnest
UNION ALL
SELECT
    source,
    c_customer_id,
    total_amount,
    attribute
FROM returns_flat
ORDER BY total_amount DESC
LIMIT 100
