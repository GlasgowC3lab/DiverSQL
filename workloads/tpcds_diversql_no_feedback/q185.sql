WITH sales_with_item AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        i.i_units,
        regexp_extract(i.i_item_desc, '[0-9]+') AS digits_in_desc,
        CONCAT(i.i_brand, '-', SUBSTRING(i.i_product_name, 1, 5)) AS brand_product_key,
        CASE WHEN regexp_like(i.i_item_desc, '.*[A-Z]{3}.*') THEN 1 ELSE 0 END AS has_three_upper
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_brand LIKE 'B%'
)
SELECT
    swi.i_brand,
    COUNT(DISTINCT swi.cs_order_number) AS orders_cnt,
    SUM(swi.cs_net_paid) AS total_net_paid,
    SUM(swi.cs_net_profit) AS total_net_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(CASE WHEN swi.has_three_upper = 1 THEN 1 ELSE 0 END) AS items_with_three_upper_desc
FROM sales_with_item swi
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = swi.cs_order_number
 AND cr.cr_item_sk = swi.cs_item_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = swi.cs_order_number
      AND cr2.cr_item_sk = swi.cs_item_sk
      AND cr2.cr_reversed_charge > 100
)
GROUP BY swi.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
