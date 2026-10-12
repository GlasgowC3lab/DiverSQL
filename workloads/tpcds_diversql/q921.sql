WITH sampled_sales AS (
        SELECT cs_sold_date_sk,
               cs_sold_time_sk,
               cs_call_center_sk,
               cs_catalog_page_sk,
               cs_ship_mode_sk,
               cs_warehouse_sk,
               cs_item_sk,
               cs_quantity,
               cs_net_paid_inc_ship_tax,
               cs_ext_discount_amt
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    common_items AS (
        SELECT cs_item_sk AS item_sk FROM sampled_sales
        INTERSECT
        SELECT sr_item_sk FROM store_returns
    ),
    base AS (
        SELECT ss.cs_sold_date_sk,
               ss.cs_sold_time_sk,
               ss.cs_call_center_sk,
               ss.cs_catalog_page_sk,
               ss.cs_ship_mode_sk,
               ss.cs_warehouse_sk,
               ss.cs_item_sk,
               ss.cs_quantity,
               ss.cs_net_paid_inc_ship_tax,
               ss.cs_ext_discount_amt,
               ci.item_sk
        FROM sampled_sales ss
        INNER JOIN common_items ci ON ss.cs_item_sk = ci.item_sk
    )
SELECT
    td.t_hour,
    d_sold.d_year,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    COUNT(DISTINCT base.cs_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_return_customers,
    SUM(base.cs_net_paid_inc_ship_tax) AS total_net_paid,
    SUM(CASE WHEN base.cs_ext_discount_amt > 100 THEN base.cs_ext_discount_amt ELSE 0 END) AS high_discount_sum,
    COUNT(*) FILTER (WHERE sr.sr_return_quantity IS NOT NULL) AS return_rows
FROM base
RIGHT OUTER JOIN time_dim td
    ON base.cs_sold_time_sk = td.t_time_sk
LEFT JOIN date_dim d_sold
    ON base.cs_sold_date_sk = d_sold.d_date_sk
LEFT JOIN call_center cc
    ON base.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON base.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON base.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON base.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
   AND sr.sr_item_sk = base.cs_item_sk
GROUP BY
    td.t_hour,
    d_sold.d_year,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name
ORDER BY total_net_paid DESC
LIMIT 100
