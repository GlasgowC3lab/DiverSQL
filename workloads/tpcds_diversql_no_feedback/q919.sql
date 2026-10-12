WITH filtered AS (
    SELECT
        d.d_year,
        concat(i.i_brand, '-', i.i_category) AS brand_category,
        r.r_reason_desc,
        w.w_warehouse_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_net_loss
    FROM tpcds.catalog_returns AS cr
    JOIN tpcds.date_dim AS d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item AS i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.warehouse AS w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.reason AS r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 1916
      AND i.i_product_name LIKE '%Gold%'
      AND regexp_like(r.r_reason_desc, '(?i)not.*product')
)
SELECT
    d_year,
    brand_category,
    r_reason_desc,
    w_warehouse_name,
    sum(cr_return_amount) AS total_return_amount,
    sum(cr_return_quantity) AS total_return_quantity,
    sum(cr_return_tax) AS total_return_tax,
    sum(cr_net_loss) AS total_net_loss
FROM filtered
GROUP BY CUBE (d_year, brand_category, r_reason_desc, w_warehouse_name)
ORDER BY total_return_amount DESC
LIMIT 100
