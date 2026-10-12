WITH sampled_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (5) -- sample ~5% of rows
) ,
joined_data AS (
    SELECT
        w.w_state,
        i.i_brand,
        i.i_product_name,
        regexp_extract(i.i_product_name, '[A-Za-z]+([0-9]+)', 1) AS product_code,
        concat(i.i_brand, ' ', i.i_product_name) AS brand_product,
        c.c_customer_id,
        ws.ws_net_paid,
        r.r_reason_desc
    FROM sampled_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_product_name, '^.*Pro.*$')
      AND r.r_reason_desc LIKE '%price%'
)
SELECT
    w_state,
    i_brand,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(DISTINCT ws_net_paid) AS sum_distinct_net_paid,
    COUNT(DISTINCT r_reason_desc) AS distinct_reasons,
    MAX(product_code) AS example_product_code,
    MIN(brand_product) AS example_brand_product
FROM joined_data
GROUP BY w_state, i_brand
ORDER BY sum_distinct_net_paid DESC
