WITH
/* First aggregation with one set of filters */
agg1 AS (
    SELECT
        cd.cd_gender                     AS gender,
        ib.ib_income_band_sk             AS income_band,
        sm.sm_type                       AS ship_type,
        td.t_hour                        AS hour,
        SUM(cr.cr_return_amount)         AS total_return_amount,
        SUM(ss.ss_ext_sales_price)       AS total_store_sales,
        SUM(ws.ws_ext_sales_price)       AS total_web_sales,
        COUNT(DISTINCT cr.cr_order_number) AS cnt_orders
    FROM
        catalog_returns cr
        JOIN catalog_page cp               ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i                        ON cr.cr_item_sk = i.i_item_sk
        JOIN time_dim td                  ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer_address ca          ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN ship_mode sm                 ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w                  ON cr.cr_warehouse_sk = w.w_warehouse_sk
        /* Store channel */
        JOIN store_sales ss               ON ss.ss_item_sk = i.i_item_sk
        JOIN store_returns sr             ON sr.sr_ticket_number = ss.ss_ticket_number
                                           AND sr.sr_item_sk = i.i_item_sk
        /* Web channel */
        JOIN web_sales ws                ON ws.ws_item_sk = i.i_item_sk
        JOIN web_returns wr               ON wr.wr_order_number = ws.ws_order_number
        JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        cr.cr_return_amount > 100
        AND i.i_current_price BETWEEN 20 AND 200
        AND cd.cd_education_status = 'College'
        AND ib.ib_upper_bound <= 100000
        AND td.t_hour BETWEEN 8 AND 18
    GROUP BY
        GROUPING SETS ( (cd.cd_gender, ib.ib_income_band_sk),
                        (sm.sm_type, td.t_hour),
                        () )
),
/* Second aggregation with a different set of filters */
agg2 AS (
    SELECT
        cd.cd_gender                     AS gender,
        ib.ib_income_band_sk             AS income_band,
        sm.sm_type                       AS ship_type,
        td.t_hour                        AS hour,
        SUM(cr.cr_return_amount)         AS total_return_amount,
        SUM(ss.ss_ext_sales_price)       AS total_store_sales,
        SUM(ws.ws_ext_sales_price)       AS total_web_sales,
        COUNT(DISTINCT cr.cr_order_number) AS cnt_orders
    FROM
        catalog_returns cr
        JOIN catalog_page cp               ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i                        ON cr.cr_item_sk = i.i_item_sk
        JOIN time_dim td                  ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer_address ca          ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN ship_mode sm                 ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w                  ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN store_sales ss               ON ss.ss_item_sk = i.i_item_sk
        JOIN store_returns sr             ON sr.sr_ticket_number = ss.ss_ticket_number
                                           AND sr.sr_item_sk = i.i_item_sk
        JOIN web_sales ws                ON ws.ws_item_sk = i.i_item_sk
        JOIN web_returns wr               ON wr.wr_order_number = ws.ws_order_number
        JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        cr.cr_return_quantity > 5
        AND i.i_color = 'Red'
        AND cd.cd_gender = 'F'
        AND ib.ib_lower_bound >= 20000
        AND sm.sm_carrier = 'UPS'
    GROUP BY
        GROUPING SETS ( (cd.cd_gender, ib.ib_income_band_sk),
                        (sm.sm_type, td.t_hour),
                        () )
),
/* Union the two aggregated results */
unioned AS (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
),
/* Final aggregation over the union, again using grouping sets */
final_agg AS (
    SELECT
        gender,
        income_band,
        ship_type,
        hour,
        SUM(total_return_amount) AS total_return_amount,
        SUM(total_store_sales)   AS total_store_sales,
        SUM(total_web_sales)     AS total_web_sales,
        SUM(cnt_orders)          AS cnt_orders
    FROM
        unioned
    GROUP BY
        GROUPING SETS ( (gender, income_band),
                        (ship_type, hour),
                        () )
)
SELECT
    gender,
    income_band,
    ship_type,
    hour,
    total_return_amount,
    total_store_sales,
    total_web_sales,
    cnt_orders,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM
    final_agg
ORDER BY
    total_return_amount DESC
LIMIT 100
