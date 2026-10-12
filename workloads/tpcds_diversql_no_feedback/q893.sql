WITH joined_data AS (
    SELECT
        w.w_state,
        sm.sm_type,
        cc.cc_name,
        hd.hd_buy_potential,
        cs.cs_net_paid_inc_tax,
        ss.ss_net_paid_inc_tax,
        ws.ws_net_paid_inc_tax,
        i.i_item_sk,
        i.i_current_price
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_wholesale_cost < 2.0
      AND cs.cs_net_paid_inc_tax > 1500
      AND ib.ib_upper_bound >= 60000
)
SELECT
    w_state,
    sm_type,
    cc_name,
    hd_buy_potential,
    SUM(cs_net_paid_inc_tax) AS total_catalog_sales,
    SUM(ss_net_paid_inc_tax) AS total_store_sales,
    SUM(ws_net_paid_inc_tax) AS total_web_sales,
    COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
    AVG(i_current_price) AS avg_item_price,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS sales_rank
FROM joined_data
GROUP BY w_state, sm_type, cc_name, hd_buy_potential
ORDER BY total_catalog_sales DESC
