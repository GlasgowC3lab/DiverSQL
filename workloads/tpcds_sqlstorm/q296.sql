WITH store_sales_agg AS (
    SELECT
        s.s_store_name AS location,
        d.d_year AS d_year,
        ss.ss_net_profit AS profit,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
),
catalog_sales_agg AS (
    SELECT
        c.cc_name AS location,
        d.d_year AS d_year,
        cs.cs_net_profit AS profit,
        cs.cs_quantity AS quantity,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
),
web_sales_agg AS (
    SELECT
        wp.wp_url AS location,
        d.d_year AS d_year,
        ws.ws_net_profit AS profit,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
)
SELECT
    channel,
    d_year,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity
FROM (
    SELECT channel, d_year, profit, quantity FROM store_sales_agg
    UNION ALL
    SELECT channel, d_year, profit, quantity FROM catalog_sales_agg
    UNION ALL
    SELECT channel, d_year, profit, quantity FROM web_sales_agg
) t
GROUP BY channel, d_year
ORDER BY channel, d_year
