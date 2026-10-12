WITH sales_data AS (
    SELECT
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        wr.wr_return_amt
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    price_category,
    wsit.web_city,
    wh.w_city AS warehouse_city,
    AVG(ext_discount) AS avg_discount,
    AVG(return_amt) AS avg_return_amt,
    DENSE_RANK() OVER (PARTITION BY price_category ORDER BY AVG(ext_discount) DESC) AS city_discount_rank
FROM (
    SELECT
        CASE
            WHEN ws_sales_price >= 200 THEN 'Premium'
            WHEN ws_sales_price >= 100 THEN 'Standard'
            ELSE 'Budget'
        END AS price_category,
        ws_ext_discount_amt AS ext_discount,
        wr_return_amt AS return_amt,
        ws_web_site_sk,
        ws_warehouse_sk
    FROM sales_data
) s
JOIN web_site wsit ON s.ws_web_site_sk = wsit.web_site_sk
JOIN warehouse wh ON s.ws_warehouse_sk = wh.w_warehouse_sk
GROUP BY price_category, wsit.web_city, wh.w_city
ORDER BY price_category, city_discount_rank
