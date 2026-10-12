WITH unified AS (
    SELECT * FROM (
        -- Web sales aggregation
        SELECT
            'web' AS source,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        GROUP BY GROUPING SETS (
            (d.d_year, d.d_month_seq),
            (d.d_year),
            ()
        )
        UNION
        -- Store returns aggregation
        SELECT
            'store' AS source,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            SUM(sr.sr_return_amt_inc_tax) AS total_sales,
            SUM(sr.sr_net_loss) AS total_profit
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        GROUP BY GROUPING SETS (
            (d.d_year, d.d_month_seq),
            (d.d_year),
            ()
        )
    ) AS u
)
SELECT
    source,
    d_year,
    d_month_seq,
    total_sales,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_sales DESC) AS sales_rank
FROM unified
ORDER BY source, sales_rank
LIMIT 100
