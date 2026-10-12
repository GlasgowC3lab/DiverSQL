WITH catalog_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        td.t_hour AS hour,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_quantity > 0
      AND cs.cs_item_sk IN (
          SELECT i2.i_item_sk
          FROM item i2
          WHERE i2.i_size = 'medium'
      )
    GROUP BY i.i_item_id, td.t_hour
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
store_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        td.t_hour AS hour,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_quantity > 0
      AND ss.ss_item_sk IN (
          SELECT i3.i_item_sk
          FROM item i3
          WHERE i3.i_size = 'medium'
      )
    GROUP BY i.i_item_id, td.t_hour
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT item_id, hour, total_sales
FROM catalog_sales_agg
UNION ALL
SELECT item_id, hour, total_sales
FROM store_sales_agg
ORDER BY total_sales DESC, item_id, hour
LIMIT 100
