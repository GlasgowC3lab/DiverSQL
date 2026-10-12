WITH store_sales_agg AS (
    SELECT
        i.i_item_id      AS item_id,
        i.i_product_name AS item_name,
        SUM(ss.ss_net_paid) AS total_sales,
        'store'          AS channel
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i          ON ss.ss_item_sk = i.i_item_sk
    JOIN store s         ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1998
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(ss.ss_net_paid) > (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 1998
    )
),

catalog_sales_agg AS (
    SELECT
        i.i_item_id      AS item_id,
        i.i_product_name AS item_name,
        SUM(cs.cs_net_paid) AS total_sales,
        'catalog'        AS channel
    FROM catalog_sales cs
    JOIN date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i            ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc    ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1998
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = cs.cs_item_sk
      )
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(cs.cs_net_paid) > (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 1998
    )
)
SELECT item_id,
       item_name,
       total_sales,
       channel
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
) AS combined
ORDER BY total_sales DESC
LIMIT 100
