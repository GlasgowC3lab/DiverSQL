WITH store_sales_agg AS (
    SELECT
        'store' AS source_type,
        s.s_store_name AS location,
        i.i_category AS item_category,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        i.i_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
        AND ss.ss_store_sk IN (
            SELECT s2.s_store_sk
            FROM store s2
            WHERE s2.s_state = 'CA'
        )
        AND ss.ss_sales_price > (
            SELECT MIN(i2.i_current_price)
            FROM item i2
            WHERE i2.i_category = 'Electronics'
        )
    GROUP BY
        s.s_store_name,
        i.i_category
),
web_sales_agg AS (
    SELECT
        'web' AS source_type,
        wp.wp_url AS location,
        i.i_category AS item_category,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        i.i_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
        AND wp.wp_url IN (
            SELECT wp2.wp_url
            FROM web_page wp2
            WHERE wp2.wp_type = 'Content'
        )
        AND ws.ws_sales_price > (
            SELECT MIN(i2.i_current_price)
            FROM item i2
            WHERE i2.i_category = 'Electronics'
        )
    GROUP BY
        wp.wp_url,
        i.i_category
)
SELECT
    source_type,
    location,
    item_category,
    total_sales
FROM (
    SELECT source_type, location, item_category, total_sales FROM store_sales_agg
    UNION ALL
    SELECT source_type, location, item_category, total_sales FROM web_sales_agg
) AS combined
ORDER BY total_sales DESC
LIMIT 100
