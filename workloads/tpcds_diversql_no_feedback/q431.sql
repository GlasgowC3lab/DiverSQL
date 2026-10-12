WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_brand,
        s.s_store_name,
        sm.sm_carrier,
        cc.cc_market_manager,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ss.ss_ext_sales_price AS store_sales_amount,
        cr.cr_return_amount,
        i.i_current_price
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
        AND i.i_current_price > 100.00
        AND w.w_warehouse_sq_ft > 500000
        AND sm.sm_code = 'AIR'
)
SELECT
    d_year,
    i_brand,
    s_store_name,
    sm_carrier,
    cc_market_manager,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(CASE WHEN cs_net_profit > 0 THEN cs_ext_sales_price ELSE 0 END) AS profitable_catalog_sales,
    AVG(i_current_price) AS avg_item_price,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Overall Profitable' ELSE 'Overall Not Profitable' END AS overall_profit_status
FROM
    joined_data
GROUP BY
    d_year,
    i_brand,
    s_store_name,
    sm_carrier,
    cc_market_manager
ORDER BY
    total_catalog_sales DESC
LIMIT 100
