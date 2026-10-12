WITH joined AS (
    SELECT
        d.d_year,
        i.i_category,
        w.w_state,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_return_quantity,
        wr.wr_return_quantity,
        inv.inv_quantity_on_hand
    FROM tpcds.date_dim d
    -- store_sales chain
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- inventory (date and item already in chain)
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    -- warehouse (via inventory)
    JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    -- catalog_returns (warehouse and date already in chain)
    JOIN tpcds.catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    -- web_sales (warehouse, date, item, household, ship mode already in chain)
    JOIN tpcds.web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
                         AND ws.ws_sold_date_sk = d.d_date_sk
                         AND ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                         AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site site ON ws.ws_web_site_sk = site.web_site_sk
    -- web_returns (order number, item, date already in chain)
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_item_sk = ws.ws_item_sk
                             AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND hd.hd_vehicle_count = 3
      AND w.w_state = 'CA'
),
agg_store AS (
    SELECT d_year,
           i_category,
           w_state,
           SUM(ss_net_paid) AS total_sales,
           COUNT(cr_return_quantity) AS total_returns,
           AVG(inv_quantity_on_hand) AS avg_inventory
    FROM joined
    GROUP BY d_year, i_category, w_state
),
agg_web AS (
    SELECT d_year,
           i_category,
           w_state,
           SUM(ws_net_paid) AS total_sales,
           COUNT(wr_return_quantity) AS total_returns,
           AVG(inv_quantity_on_hand) AS avg_inventory
    FROM joined
    GROUP BY d_year, i_category, w_state
),
combined AS (
    SELECT * FROM agg_store
    UNION DISTINCT
    SELECT * FROM agg_web
),
ranked AS (
    SELECT d_year,
           i_category,
           w_state,
           total_sales,
           total_returns,
           avg_inventory,
           ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_sales DESC) AS rk
    FROM combined
)
SELECT d_year,
       i_category,
       w_state,
       total_sales,
       total_returns,
       avg_inventory
FROM ranked
WHERE rk <= 5
ORDER BY d_year, i_category, total_sales DESC
LIMIT 100
