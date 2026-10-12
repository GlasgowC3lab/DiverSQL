WITH
store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        d.d_year AS sales_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_item_sk = ss.ss_item_sk
            AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc, d.d_year
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        d.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'ad'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc, d.d_year
),
combined_sales AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
),
inventory_sample AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10) -- approximate 10% sample
)
SELECT
    cs.i_item_id,
    cs.i_item_desc,
    cs.sales_year,
    cs.total_sales,
    cs.total_qty,
    inv.inv_quantity_on_hand,
    (SELECT AVG(cs2.cs_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = cs.i_item_sk) AS avg_catalog_price,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rn
FROM combined_sales cs
FULL OUTER JOIN inventory_sample inv
    ON cs.i_item_sk = inv.inv_item_sk
ORDER BY rn
LIMIT 100
