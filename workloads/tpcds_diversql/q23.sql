WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_with_array AS (
    SELECT
        cs.*,
        split(i.i_item_id, '') AS item_id_chars
    FROM sampled_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
)
SELECT
    cc.cc_division_name,
    i.i_category,
    td.t_meal_time,
    COUNT(DISTINCT swa.cs_order_number) AS orders,
    SUM(swa.cs_net_paid) AS total_net_paid,
    SUM(swa.cs_quantity) AS total_quantity,
    SUM(cardinality(swa.item_id_chars)) AS total_id_chars
FROM sales_with_array swa
JOIN time_dim td ON swa.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc ON swa.cs_call_center_sk = cc.cc_call_center_sk
JOIN call_center cc2 ON swa.cs_call_center_sk = cc2.cc_call_center_sk
JOIN item i ON swa.cs_item_sk = i.i_item_sk
JOIN item i2 ON swa.cs_item_sk = i2.i_item_sk
JOIN household_demographics hd_bill ON swa.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON swa.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN household_demographics hd_extra ON swa.cs_bill_hdemo_sk = hd_extra.hd_demo_sk
CROSS JOIN UNNEST(swa.item_id_chars) AS t(char)
WHERE cc.cc_rec_end_date > DATE '2000-01-01'
GROUP BY
    cc.cc_division_name,
    i.i_category,
    td.t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
