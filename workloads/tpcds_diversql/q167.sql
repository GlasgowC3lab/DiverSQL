WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
) ,
agg_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        wsite.web_name,
        wsite.web_city,
        wp.wp_url,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_return_quantity) AS distinct_return_qty
    FROM sampled_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE
        regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
        AND wsite.web_name LIKE '%Store%'
    GROUP BY
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        wsite.web_name,
        wsite.web_city,
        wp.wp_url
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS row_num,
    ws_order_number,
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    regexp_extract(c_email_address, '@(.*)$', 1) AS email_domain,
    ws_ext_sales_price,
    ws_ext_discount_amt,
    web_name,
    web_city,
    CASE
        WHEN regexp_like(wp_url, '^https?://.*promo.*$') THEN 'PromoPage'
        ELSE 'RegularPage'
    END AS page_type,
    total_return_amount,
    distinct_return_qty
FROM agg_data
ORDER BY total_return_amount DESC
LIMIT 100
