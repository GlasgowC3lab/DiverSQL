SELECT channel,
       entity_name,
       category,
       month,
       total_sales,
       total_profit,
       total_quantity
FROM (
    SELECT 'store' AS channel,
           s.s_store_name AS entity_name,
           i.i_category AS category,
           d.d_moy AS month,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_name, i.i_category, d.d_moy

    UNION ALL

    SELECT 'catalog' AS channel,
           cc.cc_name AS entity_name,
           i.i_category AS category,
           d.d_moy AS month,
           SUM(cs.cs_net_paid_inc_tax) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_name, i.i_category, d.d_moy

    UNION ALL

    SELECT 'web' AS channel,
           wp.wp_type AS entity_name,
           i.i_category AS category,
           d.d_moy AS month,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY wp.wp_type, i.i_category, d.d_moy
) t
ORDER BY total_profit DESC
LIMIT 100
