WITH catalog_filtered AS (
    SELECT DISTINCT cr.cr_item_sk
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(cp.cp_description, '(?i)prison')
      AND i.i_product_name LIKE '%Gold%'
),
web_filtered AS (
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_color, '^Red')
      AND t.t_meal_time = 'Dinner'
),
intersect_items AS (
    SELECT cr_item_sk AS item_sk FROM catalog_filtered
    INTERSECT
    SELECT wr_item_sk AS item_sk FROM web_filtered
),
returns_agg AS (
    SELECT
        i.i_brand,
        i.i_brand_id,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        COALESCE(SUM(cr.cr_return_amount), 0) + COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount
    FROM intersect_items ii
    JOIN item i
        ON ii.item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_brand, i.i_brand_id
)
SELECT
    CONCAT(brand, ' (ID:', CAST(brand_id AS varchar), ')') AS brand_label,
    brand,
    brand_id,
    total_return_amount,
    SUM(total_return_amount) OVER (
        PARTITION BY brand
        ORDER BY total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT DISTINCT
        i_brand AS brand,
        i_brand_id AS brand_id,
        total_return_amount
    FROM returns_agg
) ra
ORDER BY total_return_amount DESC
LIMIT 20
