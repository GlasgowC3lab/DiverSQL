WITH total_sales AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_net_profit AS net_profit,
        cs_order_number AS order_number,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_net_profit,
        ss_ticket_number,
        'store'
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ws_order_number,
        'web'
    FROM web_sales
)
SELECT
    d.d_year,
    i.i_category,
    i.i_class,
    total_sales.channel,
    SUM(total_sales.net_profit) AS total_profit,
    SUM(total_sales.quantity) AS total_quantity,
    COUNT(DISTINCT total_sales.order_number) AS total_orders
FROM total_sales
JOIN date_dim d ON total_sales.sold_date_sk = d.d_date_sk
JOIN item i ON total_sales.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category, i.i_class, total_sales.channel
ORDER BY total_profit DESC
LIMIT 100
