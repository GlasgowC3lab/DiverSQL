WITH sales_union AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        'Store' AS channel,
        ss.ss_net_paid AS sales_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002

    UNION ALL

    SELECT
        d.d_year AS year,
        i.i_category AS category,
        'Web' AS channel,
        ws.ws_net_paid AS sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
)
SELECT
    year,
    category,
    channel,
    SUM(sales_amount) AS total_sales
FROM sales_union
GROUP BY CUBE (year, category, channel)
ORDER BY total_sales DESC
LIMIT 100
