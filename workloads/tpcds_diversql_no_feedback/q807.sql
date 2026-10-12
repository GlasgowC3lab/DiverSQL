WITH agg_sales AS (
    SELECT
        ws_item_sk,
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
    WHERE ws_ext_sales_price > 1000
      AND ws_quantity > 0
    GROUP BY ws_item_sk, ws_web_page_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    wp.wp_url,
    wp.wp_image_count,
    agg.total_sales,
    agg.total_qty,
    agg.avg_discount,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY agg.total_sales DESC) AS brand_sales_rank,
    url_part,
    dim.dim_val,
    yr.year_val
FROM agg_sales agg
JOIN tpcds.item i
    ON agg.ws_item_sk = i.i_item_sk
JOIN tpcds.web_page wp
    ON agg.ws_web_page_sk = wp.wp_web_page_sk
-- expand the URL into its path components
CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_part)
-- a tiny dimension table
CROSS JOIN (SELECT 1 AS dim_val UNION ALL SELECT 2 UNION ALL SELECT 3) dim
-- a computed set of years
CROSS JOIN (SELECT 2020 AS year_val UNION ALL SELECT 2021 UNION ALL SELECT 2022) yr
WHERE i.i_rec_start_date >= DATE '1999-01-01'
  AND i.i_category = 'Sports'
  AND wp.wp_autogen_flag = 'N'
  AND wp.wp_image_count >= 2
  AND agg.avg_discount IS NOT NULL
ORDER BY agg.total_sales DESC, brand_sales_rank
LIMIT 100
