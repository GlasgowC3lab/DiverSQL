WITH sampled_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
),
filtered_ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk
    FROM sampled_ws ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*catalog.*$')
      AND wp.wp_type LIKE '%Home%'
)
SELECT
    agg.ws_web_site_sk,
    agg.total_net_profit,
    agg.sales_count,
    agg.first_sold_date,
    agg.last_sold_date,
    agg.site_city
FROM (
    SELECT
        fws.ws_web_site_sk,
        SUM(fws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count,
        MIN(d.d_date) AS first_sold_date,
        MAX(d.d_date) AS last_sold_date,
        ws_site.web_city AS site_city
    FROM filtered_ws fws
    JOIN date_dim d ON fws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON fws.ws_web_site_sk = ws_site.web_site_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_order_number = fws.ws_order_number
          AND regexp_like(r.r_reason_desc, '(?i)damage')
    )
    GROUP BY fws.ws_web_site_sk, ws_site.web_city
) agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
