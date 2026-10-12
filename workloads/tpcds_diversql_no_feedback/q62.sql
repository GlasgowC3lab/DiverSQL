WITH sales_agg AS (
    SELECT
        ds.d_year,
        i.i_brand,
        i.i_category,
        wp.wp_type,
        CONCAT(wp.wp_type, '_', SUBSTR(wp.wp_web_page_id, 1, 5)) AS page_key,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE REGEXP_LIKE(wp.wp_url, '^https?://.*example\\.com')
      AND i.i_item_desc LIKE '%steel%'
    GROUP BY
        ds.d_year,
        i.i_brand,
        i.i_category,
        wp.wp_type,
        CONCAT(wp.wp_type, '_', SUBSTR(wp.wp_web_page_id, 1, 5))
),
returns_agg AS (
    SELECT
        dr.d_year,
        i.i_brand,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_return_tax) AS total_return_tax
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE REGEXP_EXTRACT(CAST(wr.wr_reason_sk AS varchar), '(\\d+)$') IS NOT NULL
    GROUP BY dr.d_year, i.i_brand
)
SELECT
    s.d_year,
    s.i_brand,
    s.i_category,
    s.wp_type,
    s.page_key,
    s.total_sales,
    r.total_return,
    s.distinct_customers,
    s.distinct_orders,
    ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS rn
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year AND s.i_brand = r.i_brand
ORDER BY rn
LIMIT 100
