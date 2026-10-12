WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cc.cc_name,
    cp.cp_department,
    i.i_item_id,
    i.i_current_price,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    inv_agg.total_qty_on_hand
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE cc.cc_country = 'United States'
  AND i.i_current_price BETWEEN 20 AND 100
  AND cp.cp_department = 'Sports'
  AND hd.hd_buy_potential = '1000-2000'
  AND ib.ib_lower_bound >= 30000
  AND i.i_rec_start_date >= DATE '2000-01-01'
  AND w.w_city = 'Los Angeles'
GROUP BY
    cc.cc_name,
    cp.cp_department,
    i.i_item_id,
    i.i_current_price,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wp.wp_type,
    inv_agg.total_qty_on_hand
ORDER BY total_catalog_sales DESC
LIMIT 100
