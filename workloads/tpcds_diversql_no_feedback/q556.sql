WITH
    sales_agg AS (
        SELECT
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_buy_potential,
            cs.cs_order_number AS order_number,
            SUM(cs.cs_net_paid) AS total_net_paid,
            AVG(cs.cs_ext_discount_amt) AS avg_discount,
            COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
            CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
        FROM tpcds.catalog_sales cs
        JOIN tpcds.customer c                         ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd           ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.household_demographics hd          ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.customer_address ca                ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN tpcds.call_center cc                     ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.catalog_page cp                    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN tpcds.ship_mode sm                       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.promotion p                        ON cs.cs_promo_sk = p.p_promo_sk
        JOIN tpcds.catalog_returns cr                 ON cr.cr_order_number = cs.cs_order_number
        JOIN tpcds.reason r_cr                        ON cr.cr_reason_sk = r_cr.r_reason_sk
        JOIN tpcds.store_returns sr                  ON sr.sr_customer_sk = c.c_customer_sk
        JOIN tpcds.reason r_sr                        ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN tpcds.web_sales ws                      ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.web_returns wr                    ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN tpcds.reason r_wr                        ON wr.wr_reason_sk = r_wr.r_reason_sk
        WHERE
            hd.hd_vehicle_count = 2
            AND hd.hd_buy_potential = '5001-10000'
            AND cd.cd_gender = 'M'
            AND r_cr.r_reason_desc LIKE '%size%'
            AND r_sr.r_reason_desc = 'Gift exchange'
            AND cr.cr_return_quantity > 0
        GROUP BY
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_buy_potential,
            cs.cs_order_number
    ),
    web_agg AS (
        SELECT
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_buy_potential,
            ws.ws_order_number AS order_number,
            SUM(ws.ws_net_paid) AS total_net_paid,
            AVG(ws.ws_ext_discount_amt) AS avg_discount,
            COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
            CASE WHEN SUM(ws.ws_net_profit) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
        FROM tpcds.web_sales ws
        JOIN tpcds.customer c                         ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd           ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.household_demographics hd          ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.customer_address ca                ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN tpcds.ship_mode sm                       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.promotion p                        ON ws.ws_promo_sk = p.p_promo_sk
        JOIN tpcds.web_returns wr                     ON wr.wr_order_number = ws.ws_order_number
        JOIN tpcds.reason r_wr                        ON wr.wr_reason_sk = r_wr.r_reason_sk
        WHERE
            hd.hd_vehicle_count = 3
            AND hd.hd_buy_potential = '1001-5000'
            AND cd.cd_gender = 'F'
            AND r_wr.r_reason_desc = 'Parts missing'
            AND ws.ws_quantity > 1
            AND ws.ws_net_paid > 0
        GROUP BY
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_buy_potential,
            ws.ws_order_number
    ),
    combined AS (
        SELECT * FROM sales_agg
        UNION DISTINCT
        SELECT * FROM web_agg
    )
SELECT
    c_customer_id,
    cd_gender,
    hd_buy_potential,
    total_net_paid,
    avg_discount,
    distinct_items,
    profit_category
FROM combined
WHERE order_number NOT IN (
    SELECT sr_ticket_number
    FROM tpcds.store_returns
    WHERE sr_return_quantity > 5
)
ORDER BY total_net_paid DESC
LIMIT 100
