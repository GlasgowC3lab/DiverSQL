WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
), aggregated AS (
    SELECT
        d.d_year AS year,
        us.channel,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        SUM(us.net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, us.channel, i.i_category, i.i_class, i.i_brand
), ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.channel ORDER BY a.total_net_profit DESC) AS rn
    FROM aggregated a
)
SELECT
    year,
    channel,
    category,
    class,
    brand,
    total_net_profit,
    sales_cnt
FROM ranked
WHERE rn <= 50
ORDER BY channel, total_net_profit DESC
