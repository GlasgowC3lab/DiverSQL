WITH
    store_part AS (
        SELECT
            d.d_year AS year,
            ca.ca_state,
            regexp_extract(ca.ca_city, '^([A-Za-z]+)', 1) AS city_prefix,
            SUM(ss.ss_ext_sales_price) AS sales_amount,
            COUNT(DISTINCT ss.ss_customer_sk) AS customer_cnt
        FROM store_sales ss
        RIGHT OUTER JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2022
          AND (regexp_like(ca.ca_city, '^A.*') OR ca.ca_city LIKE '%town%')
        GROUP BY d.d_year, ca.ca_state, regexp_extract(ca.ca_city, '^([A-Za-z]+)', 1)
    ),
    web_part AS (
        SELECT
            d.d_year AS year,
            ca.ca_state,
            regexp_extract(ca.ca_city, '^([A-Za-z]+)', 1) AS city_prefix,
            SUM(ws.ws_ext_sales_price) AS sales_amount,
            COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_cnt
        FROM web_sales ws
        RIGHT OUTER JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN customer_address ca
            ON ws.ws_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE d.d_year = 2022
          AND (regexp_like(wp.wp_url, 'promo[0-9]+') OR wp.wp_type LIKE 'article%')
        GROUP BY d.d_year, ca.ca_state, regexp_extract(ca.ca_city, '^([A-Za-z]+)', 1)
    ),
    combined AS (
        SELECT year, ca_state, city_prefix, sales_amount, customer_cnt FROM store_part
        UNION
        SELECT year, ca_state, city_prefix, sales_amount, customer_cnt FROM web_part
    )
SELECT
    year,
    ca_state,
    city_prefix,
    SUM(sales_amount) AS total_sales_amount,
    SUM(customer_cnt) AS total_customer_cnt
FROM combined
GROUP BY year, ca_state, city_prefix
ORDER BY total_sales_amount DESC
LIMIT 100
