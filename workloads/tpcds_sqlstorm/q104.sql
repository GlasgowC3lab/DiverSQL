WITH catalog_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        'Catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category, i.i_brand
), store_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        'Store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category, i.i_brand
), web_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        'Web' AS channel,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category, i.i_brand
)
SELECT
    year,
    category,
    brand,
    channel,
    net_paid,
    net_profit,
    quantity,
    orders,
    net_paid / NULLIF(orders, 0) AS avg_order_value,
    net_profit / NULLIF(quantity, 0) AS profit_per_item,
    RANK() OVER (PARTITION BY year ORDER BY net_paid DESC) AS year_rank
FROM (
    SELECT d_year AS year, i_category AS category, i_brand AS brand, channel, net_paid, net_profit, quantity, orders FROM catalog_agg
    UNION ALL
    SELECT d_year, i_category, i_brand, channel, net_paid, net_profit, quantity, orders FROM store_agg
    UNION ALL
    SELECT d_year, i_category, i_brand, channel, net_paid, net_profit, quantity, orders FROM web_agg
) t
ORDER BY year, net_paid DESC
LIMIT 100
