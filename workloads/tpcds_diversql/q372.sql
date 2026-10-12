/*
Goal: Identify the most profitable product categories sold on the web in 2001 where the associated web page URL contains a '/view/' segment, exclude any orders that were returned, and enrich the result with string‑derived fields (region code, product name prefixes). The query builds a cartesian product between the single year 2001 and a small list of target categories, then joins the filtered sales to that cross‑joined set, aggregates profit and quantity, orders by profit and limits to the top 100 rows.
*/
WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_bill_addr_sk,
        d.d_year,
        i.i_category,
        i.i_product_name,
        w.w_warehouse_name,
        wp.wp_url,
        ca.ca_state,
        ca.ca_zip
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i          ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w    ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp    ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND regexp_like(wp.wp_url, '.*\/view\/.*')
      AND ca.ca_state LIKE 'C%'
      AND ws.ws_order_number NOT IN (
          SELECT wr.wr_order_number
          FROM web_returns wr
      )
),
category_cross AS (
    SELECT dy.d_year, vc.category
    FROM (
        SELECT DISTINCT d_year
        FROM date_dim
        WHERE d_year = 2001
    ) dy
    CROSS JOIN (VALUES
        ('Electronics'),
        ('Furniture'),
        ('Sports')
    ) AS vc(category)
)
SELECT
    fs.d_year,
    cc.category,
    CONCAT(fs.ca_state, '-', fs.ca_zip) AS region_code,
    SUBSTRING(fs.i_product_name, 1, 10) AS product_prefix,
    REGEXP_EXTRACT(fs.i_product_name, '^([^ ]+)', 1) AS first_word,
    SUM(fs.ws_net_profit) AS total_profit,
    SUM(fs.ws_quantity) AS total_quantity,
    COUNT(DISTINCT fs.ws_order_number) AS orders_count
FROM filtered_sales fs
JOIN category_cross cc
    ON fs.d_year = cc.d_year
   AND fs.i_category = cc.category
GROUP BY
    fs.d_year,
    cc.category,
    CONCAT(fs.ca_state, '-', fs.ca_zip),
    SUBSTRING(fs.i_product_name, 1, 10),
    REGEXP_EXTRACT(fs.i_product_name, '^([^ ]+)', 1)
ORDER BY total_profit DESC
LIMIT 100
