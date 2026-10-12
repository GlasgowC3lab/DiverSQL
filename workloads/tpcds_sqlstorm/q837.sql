WITH store_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
), catalog_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
), web_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
), combined_sales AS (
    SELECT d_year, i_category, i_brand, SUM(net_profit) AS total_net_profit, SUM(net_paid) AS total_net_paid
    FROM (
        SELECT d_year, i_category, i_brand, net_profit, net_paid FROM store_sales_agg
        UNION ALL
        SELECT d_year, i_category, i_brand, net_profit, net_paid FROM catalog_sales_agg
        UNION ALL
        SELECT d_year, i_category, i_brand, net_profit, net_paid FROM web_sales_agg
    ) a
    GROUP BY d_year, i_category, i_brand
)
SELECT d_year, i_category, i_brand, total_net_paid, total_net_profit
FROM combined_sales
WHERE d_year BETWEEN 1997 AND 1999
ORDER BY total_net_profit DESC
LIMIT 100
