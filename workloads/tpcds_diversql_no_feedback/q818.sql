WITH cr_join AS (
    SELECT
        cr.cr_returned_date_sk,
        dd.d_date,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cp.cp_description,
        cp.cp_type,
        i.i_item_desc,
        i.i_product_name,
        i.i_brand,
        w.w_city,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE dd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND REGEXP_LIKE(cp.cp_description, '.*Discount.*')
      AND i.i_product_name LIKE '%Deluxe%'
)
SELECT
    cp.cp_description,
    REGEXP_EXTRACT(cp.cp_description, '(\\d+)%', 1) AS discount_pct,
    CONCAT(cp.cp_type, '_', i.i_brand) AS type_brand,
    w.w_city,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss
FROM cr_join cr
JOIN catalog_page cp ON cr.cp_description = cp.cp_description
JOIN item i ON cr.i_product_name = i.i_product_name
JOIN warehouse w ON cr.w_city = w.w_city
GROUP BY
    cp.cp_description,
    REGEXP_EXTRACT(cp.cp_description, '(\\d+)%', 1),
    CONCAT(cp.cp_type, '_', i.i_brand),
    w.w_city
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
