WITH
  catalog_base AS (
    SELECT
      i.i_category AS category,
      td.t_meal_time AS meal_time,
      cd.cd_gender AS attribute,
      SUM(cs.cs_net_paid) AS net_paid,
      ARRAY_AGG(DISTINCT i.i_item_id) AS items_arr
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category IN ('Sports', 'Clothing', 'Electronics')
    GROUP BY CUBE(i.i_category, td.t_meal_time, cd.cd_gender)
  ),
  catalog_expanded AS (
    SELECT
      category,
      meal_time,
      attribute,
      net_paid,
      item_id
    FROM catalog_base
    CROSS JOIN UNNEST(items_arr) AS t(item_id)
  ),
  store_base AS (
    SELECT
      i.i_category AS category,
      td.t_meal_time AS meal_time,
      CAST(hd.hd_vehicle_count AS varchar) AS attribute,
      SUM(ss.ss_net_paid) AS net_paid,
      ARRAY_AGG(DISTINCT i.i_item_id) AS items_arr
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_quantity > 0
    GROUP BY CUBE(i.i_category, td.t_meal_time, hd.hd_vehicle_count)
  ),
  store_expanded AS (
    SELECT
      category,
      meal_time,
      attribute,
      net_paid,
      item_id
    FROM store_base
    CROSS JOIN UNNEST(items_arr) AS t(item_id)
  )
SELECT
  category,
  meal_time,
  attribute,
  net_paid,
  item_id
FROM catalog_expanded
UNION ALL
SELECT
  category,
  meal_time,
  attribute,
  net_paid,
  item_id
FROM store_expanded
LIMIT 100
