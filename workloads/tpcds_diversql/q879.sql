WITH sampled_sales AS (
    SELECT ss.ss_item_sk,
           ss.ss_sold_date_sk,
           ss.ss_quantity,
           ss.ss_ext_sales_price
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    WHERE ss.ss_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
),
intersect_items AS (
    SELECT item_sk FROM (
        SELECT ss_item_sk AS item_sk
        FROM sampled_sales
        WHERE ss_quantity > 5
        INTERSECT
        SELECT cr.cr_item_sk AS item_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND cr.cr_return_amount > 100
    ) AS i
)
SELECT
    i.i_item_id,
    i.i_brand,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT SUM(p.p_cost)
     FROM promotion p
     WHERE p.p_item_sk = i.i_item_sk) AS total_promo_cost
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE ss.ss_item_sk IN (SELECT item_sk FROM intersect_items)
GROUP BY i.i_item_id, i.i_brand, i.i_item_sk

UNION

SELECT
    i.i_item_id,
    i.i_brand,
    -SUM(cr.cr_return_amount) AS total_sales,
    CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT SUM(p.p_cost)
     FROM promotion p
     WHERE p.p_item_sk = i.i_item_sk) AS total_promo_cost
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
WHERE cr.cr_item_sk IN (SELECT item_sk FROM intersect_items)
GROUP BY i.i_item_id, i.i_brand, i.i_item_sk

ORDER BY total_sales DESC
LIMIT 100
