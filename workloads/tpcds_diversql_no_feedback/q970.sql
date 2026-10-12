WITH sales_agg AS (
    SELECT
        w.w_city,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        MIN(i.i_product_name) AS sample_product
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_product_name, '\\b(Deluxe|Premium)\\b')
      AND w.w_city LIKE 'A%'
      AND sm.sm_carrier = 'UPS'
    GROUP BY w.w_city, i.i_brand
)
SELECT
    sa.w_city,
    sa.i_brand,
    sa.total_sales,
    sa.order_cnt,
    sa.sample_product,
    regexp_extract(sa.sample_product, '(\\w+)$', 1) AS product_suffix,
    concat(sa.w_city, ':', sa.i_brand) AS city_brand,
    (
        SELECT SUM(cs2.cs_quantity)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_brand = sa.i_brand
    ) AS total_quantity_brand,
    row_number() OVER (ORDER BY sa.total_sales DESC) AS rank
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
