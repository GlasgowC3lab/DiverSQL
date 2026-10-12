WITH
    sales_sample AS (
        SELECT ws.ws_sold_date_sk,
               ws.ws_sold_time_sk,
               ws.ws_item_sk,
               ws.ws_bill_customer_sk,
               ws.ws_web_site_sk,
               ws.ws_net_profit,
               ws.ws_order_number
        FROM web_sales ws
        TABLESAMPLE BERNOULLI (5)
    ),
    returns_sample AS (
        SELECT wr.wr_item_sk
        FROM web_returns wr
        TABLESAMPLE BERNOULLI (5)
    ),
    sold_items AS (
        SELECT DISTINCT ws_item_sk
        FROM sales_sample
    ),
    returned_items AS (
        SELECT DISTINCT wr_item_sk
        FROM returns_sample
    ),
    net_items AS (
        SELECT ws_item_sk
        FROM sold_items
        EXCEPT
        SELECT wr_item_sk
        FROM returned_items
    ),
    sales_with_details AS (
        SELECT s.ws_web_site_sk,
               i.i_item_sk,
               i.i_item_desc,
               i.i_product_name,
               s.ws_net_profit,
               web.web_name,
               CASE 
                   WHEN s.ws_net_profit > 1000 THEN 'High'
                   ELSE 'Low'
               END AS profit_category,
               regexp_extract(i.i_item_desc, '(\\d{3})') AS three_digit_code,
               web.web_name || ' - ' || i.i_product_name AS site_product
        FROM sales_sample s
        JOIN net_items ni ON s.ws_item_sk = ni.ws_item_sk
        JOIN item i ON s.ws_item_sk = i.i_item_sk
        JOIN web_site web ON s.ws_web_site_sk = web.web_site_sk
        WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
          AND web.web_name LIKE '%Shop%'
    )
SELECT
    COALESCE(swd.site_product, w.web_name) AS site_product,
    COALESCE(swd.web_name, w.web_name) AS web_name,
    swd.profit_category,
    swd.three_digit_code,
    SUM(swd.ws_net_profit) AS total_profit
FROM sales_with_details swd
RIGHT OUTER JOIN web_site w
    ON swd.ws_web_site_sk = w.web_site_sk
GROUP BY
    COALESCE(swd.site_product, w.web_name),
    COALESCE(swd.web_name, w.web_name),
    swd.profit_category,
    swd.three_digit_code
ORDER BY total_profit DESC
LIMIT 100
