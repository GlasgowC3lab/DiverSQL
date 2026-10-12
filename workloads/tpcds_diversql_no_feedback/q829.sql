WITH intersect_items AS (
        SELECT i.i_item_id
        FROM item i
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_quantity > 0
        INTERSECT
        SELECT i2.i_item_id
        FROM item i2
        JOIN store_sales ss ON ss.ss_item_sk = i2.i_item_sk
        WHERE ss.ss_quantity > 0
    ),
    main AS (
        SELECT
            i.i_item_id,
            i.i_color,
            i.i_current_price,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type,
            d_cs.d_year AS sales_year,
            SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
            SUM(ss.ss_ext_sales_price) AS total_store_sales,
            COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
            SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_store_returns,
            SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_web_returns
        FROM catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
        -- join store_sales via the common item
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        -- store returns (left join to keep catalog rows even without returns)
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = i.i_item_sk
        LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        -- web returns (left join)
        LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
        WHERE
            i.i_color = 'red'
            AND i.i_wholesale_cost BETWEEN 1.00 AND 5.00
            AND sm.sm_code = 'AIR'
            AND cc.cc_county = 'Bronx County'
            AND d_cs.d_year = 2001
            AND NOT EXISTS (
                SELECT 1
                FROM inventory inv
                WHERE inv.inv_item_sk = i.i_item_sk
                  AND inv.inv_date_sk = d_cs.d_date_sk
            )
            AND i.i_item_id IN (SELECT i_item_id FROM intersect_items)
        GROUP BY
            i.i_item_id,
            i.i_color,
            i.i_current_price,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type,
            d_cs.d_year
    )
SELECT *
FROM main
ORDER BY total_catalog_sales DESC
LIMIT 100
