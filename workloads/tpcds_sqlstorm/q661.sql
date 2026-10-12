WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_wholesale_cost AS ext_wholesale_cost,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_wholesale_cost,
        'web'
    FROM web_sales ws
),
sales_date_item AS (
    SELECT
        s.date_sk,
        s.item_sk,
        s.net_profit,
        s.ext_sales_price,
        s.ext_wholesale_cost,
        s.sales_channel,
        d.d_year,
        d.d_month_seq,
        i.i_category
    FROM unified_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year = 2002
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        sales_channel,
        i_category,
        SUM(net_profit) AS total_profit,
        SUM(ext_sales_price) AS total_sales,
        SUM(ext_sales_price) - SUM(ext_wholesale_cost) AS gross_margin
    FROM sales_date_item
    GROUP BY CUBE (d_year, d_month_seq, sales_channel, i_category)
)
SELECT
    d_year,
    d_month_seq,
    COALESCE(sales_channel, 'ALL') AS sales_channel,
    COALESCE(i_category, 'ALL') AS item_category,
    total_profit,
    total_sales,
    gross_margin,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    CASE WHEN i_category IS NOT NULL THEN category_rank END AS category_profit_rank
FROM (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq, sales_channel ORDER BY total_profit DESC) AS category_rank
    FROM aggregated
) ranked
WHERE (i_category IS NOT NULL AND category_rank <= 5) OR i_category IS NULL
ORDER BY d_year, d_month_seq, sales_channel, category_profit_rank
