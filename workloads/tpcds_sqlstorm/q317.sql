SELECT
    channel,
    sale_year,
    sale_month,
    total_sales,
    total_profit,
    rank() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        'store' AS channel,
        d.d_year AS sale_year,
        d.d_month_seq AS sale_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq

    UNION ALL

    SELECT
        'web' AS channel,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq

    UNION ALL

    SELECT
        'catalog' AS channel,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
) agg
WHERE sale_year = 1998
ORDER BY total_sales DESC
LIMIT 100
