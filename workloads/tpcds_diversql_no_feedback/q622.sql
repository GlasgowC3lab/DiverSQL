WITH catalog AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        'catalog' AS sales_source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_item_desc
),
store AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        'store' AS sales_source
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT
    catalog.i_item_id,
    catalog.i_item_desc,
    catalog.total_net_paid,
    catalog.total_profit,
    catalog.profit_category,
    catalog.sales_source
FROM catalog
UNION ALL
SELECT
    store.i_item_id,
    store.i_item_desc,
    store.total_net_paid,
    store.total_profit,
    store.profit_category,
    store.sales_source
FROM store
ORDER BY total_profit DESC
LIMIT 100
