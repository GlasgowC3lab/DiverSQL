WITH sampled_sales AS (
    SELECT cs.*
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_category,
    w.w_warehouse_name,
    SUM(cs.cs_net_paid_inc_ship_tax)               AS total_net_paid,
    AVG(cs.cs_quantity)                            AS avg_quantity,
    COUNT(*)                                        AS sales_count,
    MIN(cs.cs_net_paid_inc_ship_tax)               AS min_net_paid,
    MAX(cs.cs_net_paid_inc_ship_tax)               AS max_net_paid,
    (
        SELECT MAX(i2.i_current_price)
        FROM tpcds.item i2
        WHERE i2.i_category = i.i_category
    )                                                AS max_category_price
FROM sampled_sales cs
JOIN tpcds.time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE
    cs.cs_net_paid_inc_ship_tax > 2000.00
    AND cs.cs_quantity >= 2
    AND i.i_color = 'sandy'
    AND ib.ib_lower_bound >= 130000
    AND td.t_hour BETWEEN 9 AND 17
    AND w.w_state = 'CA'
GROUP BY
    i.i_category,
    w.w_warehouse_name
HAVING
    SUM(cs.cs_net_paid_inc_ship_tax) > 5000
ORDER BY
    total_net_paid DESC
LIMIT 100
