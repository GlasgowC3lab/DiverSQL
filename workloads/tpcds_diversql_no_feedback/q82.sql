WITH
    all_data AS (
        SELECT
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_profit,
            d_sold.d_year               AS sold_year,
            t_sold.t_shift              AS sold_shift,
            cp.cp_department,
            i.i_category,
            ca_bill.ca_state,
            hd_bill.hd_income_band_sk,
            ib.ib_lower_bound,
            s.s_store_name,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            d_ret.d_year                AS return_year,
            t_ret.t_shift               AS return_shift,
            wr.wr_return_amt,
            wr.wr_return_quantity,
            d_wr_ret.d_year             AS web_return_year,
            t_wr_ret.t_shift            AS web_return_shift,
            wp.wp_type,
            ws.web_name
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
        LEFT JOIN web_returns wr ON wr.wr_item_sk = cs.cs_item_sk
        LEFT JOIN date_dim d_wr_ret ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
        LEFT JOIN time_dim t_wr_ret ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d_wp_creation.d_date_sk
        LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
        LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    ),
    q1 AS (
        SELECT
            sold_year AS year,
            cp_department AS department,
            SUM(cs_net_profit) AS profit
        FROM all_data
        GROUP BY sold_year, cp_department
        HAVING SUM(cs_quantity) > 10
    ),
    q2 AS (
        SELECT
            sold_year AS year,
            cp_department AS department,
            SUM(cs_net_profit) AS profit
        FROM all_data
        WHERE ca_state = 'CA'
        GROUP BY sold_year, cp_department
        HAVING SUM(cs_quantity) > 5
    ),
    intersect_q AS (
        SELECT * FROM q1 INTERSECT SELECT * FROM q2
    ),
    q3 AS (
        SELECT
            sold_year AS year,
            cp_department AS department,
            SUM(cs_net_profit) AS profit
        FROM all_data
        WHERE web_name = 'Online Store'
        GROUP BY sold_year, cp_department
    )
SELECT * FROM intersect_q
UNION
SELECT * FROM q3
ORDER BY year DESC, department
LIMIT 100
