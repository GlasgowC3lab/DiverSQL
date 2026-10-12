SELECT
    year,
    state,
    channel,
    category,
    brand,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS total_transactions
FROM (
    SELECT d.d_year AS year,
           s.s_state AS state,
           'store' AS channel,
           i.i_category AS category,
           i.i_brand AS brand,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT d.d_year AS year,
           w.w_state AS state,
           'catalog' AS channel,
           i.i_category AS category,
           i.i_brand AS brand,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT d.d_year AS year,
           w.w_state AS state,
           'web' AS channel,
           i.i_category AS category,
           i.i_brand AS brand,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
) AS combined
GROUP BY year, state, channel, category, brand
ORDER BY year, state, channel, category, brand
