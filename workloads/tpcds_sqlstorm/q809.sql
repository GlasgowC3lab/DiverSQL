SELECT
    channel,
    brand,
    year,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM (
    SELECT
        'catalog' AS channel,
        i.i_brand AS brand,
        d.d_year AS year,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002

    UNION ALL

    SELECT
        'store' AS channel,
        i.i_brand AS brand,
        d.d_year AS year,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002

    UNION ALL

    SELECT
        'web' AS channel,
        i.i_brand AS brand,
        d.d_year AS year,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
) t
GROUP BY
    channel,
    brand,
    year
ORDER BY total_net_paid DESC
LIMIT 100
