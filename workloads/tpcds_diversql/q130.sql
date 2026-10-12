WITH ss_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_ext_tax) AS sum_ext_tax,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(*) AS sales_cnt,
        MAX(ss_net_paid_inc_tax) AS max_net_paid_inc_tax
    FROM store_sales
    WHERE ss_ext_tax > 5.00
        AND ss_sales_price BETWEEN 10.00 AND 100.00
        AND ss_quantity >= 1
        AND ss_net_paid_inc_tax < 2000.00
    GROUP BY ss_item_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY i.i_item_id) AS row_num,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_color,
    ss_agg.sales_cnt,
    ss_agg.sum_ext_tax,
    ss_agg.avg_sales_price,
    ss_agg.max_net_paid_inc_tax
FROM ss_agg
RIGHT OUTER JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
WHERE i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_rec_end_date <= DATE '2002-12-31'
    AND i.i_brand = 'BrandA'
    AND i.i_color = 'Red'
ORDER BY i.i_item_id
LIMIT 100
