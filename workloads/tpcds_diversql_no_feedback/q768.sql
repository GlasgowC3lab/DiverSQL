WITH inventory_full AS (
    SELECT
        inv.inv_item_sk,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM inventory inv
    FULL OUTER JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
),
returns_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(price|color)')
    GROUP BY wr.wr_item_sk
),
reason_subset AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_id LIKE 'AAAAAAA%'
),
months AS (
    SELECT month_num
    FROM (VALUES 1,2,3,4,5,6,7,8,9,10,11,12) AS t(month_num)
)
SELECT
    COALESCE(ii.i_item_sk, ii.inv_item_sk) AS item_key,
    ii.i_product_name,
    concat(ii.i_brand, ' - ', ii.i_product_name) AS brand_product,
    ii.inv_quantity_on_hand,
    ra.total_return_qty,
    ra.total_return_amt,
    rs.r_reason_desc,
    m.month_num
FROM inventory_full ii
LEFT JOIN returns_agg ra
    ON ii.i_item_sk = ra.wr_item_sk
CROSS JOIN reason_subset rs
CROSS JOIN months m
WHERE (ii.i_product_name IS NOT NULL AND regexp_like(ii.i_product_name, '.*[0-9]{2,}.*'))
  AND (ii.i_category LIKE 'Electronics%')
ORDER BY ii.inv_quantity_on_hand DESC NULLS LAST, m.month_num
LIMIT 100
