WITH sales_by_ship AS (
    SELECT
        sold_d.d_date AS sale_date,
        sm.sm_ship_mode_id,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_quantity AS quantity,
        SUM(cs.cs_ext_sales_price) OVER (
            PARTITION BY sm.sm_ship_mode_id
            ORDER BY sold_d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN date_dim sold_d ON cs.cs_sold_date_sk = sold_d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR       '
      AND sold_d.d_year = 1998
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim promo_start ON p.p_start_date_sk = promo_start.d_date_sk
          WHERE p.p_item_sk = cs.cs_item_sk
            AND promo_start.d_date <= sold_d.d_date
      )
)
SELECT
    sale_date,
    sm_ship_mode_id,
    ext_sales_price,
    running_sales
FROM sales_by_ship
WHERE quantity > 0

UNION ALL

SELECT
    sale_date,
    sm_ship_mode_id,
    ext_sales_price,
    running_sales
FROM (
    SELECT
        sold_d.d_date AS sale_date,
        sm.sm_ship_mode_id,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_quantity AS quantity,
        SUM(cs.cs_ext_sales_price) OVER (
            PARTITION BY sm.sm_ship_mode_id
            ORDER BY sold_d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN date_dim sold_d ON cs.cs_sold_date_sk = sold_d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'SEA       '
      AND sold_d.d_year = 1998
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim promo_start ON p.p_start_date_sk = promo_start.d_date_sk
          WHERE p.p_item_sk = cs.cs_item_sk
            AND promo_start.d_date <= sold_d.d_date
      )
) sub
WHERE quantity > 0
ORDER BY sale_date, sm_ship_mode_id
