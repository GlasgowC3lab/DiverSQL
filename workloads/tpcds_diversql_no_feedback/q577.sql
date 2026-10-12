WITH inv_pos_items AS (
    SELECT inv_item_sk
    FROM tpcds.inventory
    WHERE inv_quantity_on_hand > 0
    EXCEPT
    SELECT inv_item_sk
    FROM tpcds.inventory
    WHERE inv_quantity_on_hand = 0
)
SELECT
    d1.d_date AS sales_date,
    s1.s_store_name,
    cc1.cc_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    SUM(inv1.inv_quantity_on_hand) AS inv_qty_on_day1,
    SUM(inv2.inv_quantity_on_hand) AS inv_qty_on_day2
FROM tpcds.store_sales ss
INNER JOIN tpcds.date_dim d1
    ON ss.ss_sold_date_sk = d1.d_date_sk
INNER JOIN tpcds.time_dim t1
    ON ss.ss_sold_time_sk = t1.t_time_sk
INNER JOIN tpcds.store s1
    ON ss.ss_store_sk = s1.s_store_sk
INNER JOIN tpcds.call_center cc1
    ON cc1.cc_closed_date_sk = d1.d_date_sk
INNER JOIN tpcds.inventory inv1
    ON inv1.inv_date_sk = d1.d_date_sk
INNER JOIN tpcds.date_dim d2
    ON s1.s_closed_date_sk = d2.d_date_sk
INNER JOIN tpcds.inventory inv2
    ON inv2.inv_date_sk = d2.d_date_sk
FULL OUTER JOIN tpcds.date_dim d3
    ON s1.s_closed_date_sk = d3.d_date_sk
RIGHT OUTER JOIN tpcds.call_center cc2
    ON cc2.cc_open_date_sk = d3.d_date_sk
INNER JOIN inv_pos_items ipi
    ON ipi.inv_item_sk = ss.ss_item_sk
WHERE d1.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
GROUP BY d1.d_date, s1.s_store_name, cc1.cc_name
ORDER BY total_sales DESC
LIMIT 100
