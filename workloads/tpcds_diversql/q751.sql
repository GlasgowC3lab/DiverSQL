WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_class,
        i.i_category,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_net_paid) AS total_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_class, i.i_category
)
SELECT
    i.i_item_id,
    i.i_class,
    cp.cp_department,
    w.w_state,
    sm.sm_carrier,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    SUM(cs.cs_net_paid) AS sum_net_paid,
    AVG(ws.ws_sales_price) AS avg_web_sales_price,
    SUM(ss.ss_ext_discount_amt) AS sum_store_discount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    isales.total_qty,
    isales.total_paid,
    (SELECT AVG(cs_sub.cs_quantity) FROM catalog_sales cs_sub WHERE cs_sub.cs_sold_date_sk = 2451910) AS avg_quantity_all_dates,
    SUM(CASE WHEN cs.cs_quantity > (SELECT AVG(cs_sub2.cs_quantity) FROM catalog_sales cs_sub2 WHERE cs_sub2.cs_sold_date_sk = 2451910) THEN 1 ELSE 0 END) AS qty_above_avg_count
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN item_sales isales ON i.i_item_sk = isales.i_item_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_time_sk = t.t_time_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk AND ws.ws_sold_time_sk = t.t_time_sk
WHERE
    i.i_class = 'pants'
    AND sm.sm_carrier = 'UPS'
    AND t.t_hour BETWEEN 9 AND 17
    AND w.w_state = 'CA'
    AND ib.ib_upper_bound < 80000
GROUP BY
    i.i_item_id,
    i.i_class,
    cp.cp_department,
    w.w_state,
    sm.sm_carrier,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END,
    isales.total_qty,
    isales.total_paid
ORDER BY sum_net_paid DESC
LIMIT 100
