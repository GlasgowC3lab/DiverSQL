WITH
    catalog_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            SUM(cs.cs_net_paid) AS catalog_net_paid,
            MAX(cs.cs_call_center_sk) AS call_center_sk,
            MAX(cs.cs_catalog_page_sk) AS catalog_page_sk,
            MAX(cs.cs_ship_mode_sk) AS ship_mode_sk,
            MAX(cs.cs_warehouse_sk) AS warehouse_sk,
            MAX(cs.cs_promo_sk) AS promo_sk,
            MAX(cs.cs_bill_addr_sk) AS bill_addr_sk,
            MAX(cs.cs_bill_cdemo_sk) AS bill_cdemo_sk,
            MAX(cs.cs_bill_hdemo_sk) AS bill_hdemo_sk
        FROM catalog_sales cs
        GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk
    ),
    store_agg AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_returned_date_sk,
            sr.sr_return_time_sk,
            SUM(sr.sr_return_amt) AS return_amt,
            MAX(sr.sr_addr_sk) AS return_addr_sk,
            MAX(sr.sr_cdemo_sk) AS return_cdemo_sk,
            MAX(sr.sr_hdemo_sk) AS return_hdemo_sk
        FROM store_returns sr
        GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_return_time_sk
    ),
    web_agg AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            SUM(ws.ws_net_paid) AS web_net_paid,
            MAX(ws.ws_web_page_sk) AS web_page_sk,
            MAX(ws.ws_web_site_sk) AS web_site_sk,
            MAX(ws.ws_ship_mode_sk) AS ship_mode_sk,
            MAX(ws.ws_warehouse_sk) AS warehouse_sk,
            MAX(ws.ws_promo_sk) AS promo_sk,
            MAX(ws.ws_bill_addr_sk) AS bill_addr_sk,
            MAX(ws.ws_bill_cdemo_sk) AS bill_cdemo_sk,
            MAX(ws.ws_bill_hdemo_sk) AS bill_hdemo_sk
        FROM web_sales ws
        GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, ws.ws_sold_time_sk
    ),
    joined AS (
        SELECT
            i.i_item_id,
            i.i_product_name,
            cc.cc_name                         AS call_center_name,
            cp.cp_department                    AS cp_department,
            sm.sm_type                          AS ship_mode_type,
            w.w_warehouse_name                  AS warehouse_name,
            p.p_promo_name                      AS promo_name,
            ca.ca_city                          AS bill_city,
            td_cs.t_hour                        AS sale_hour,
            COALESCE(ca_agg.catalog_net_paid, 0) AS catalog_net_paid,
            COALESCE(wa_agg.web_net_paid, 0)    AS web_net_paid,
            COALESCE(sa_agg.return_amt, 0) * -1 AS return_amt
        FROM item i
        LEFT JOIN catalog_agg ca_agg ON i.i_item_sk = ca_agg.cs_item_sk
        LEFT JOIN store_agg sa_agg   ON i.i_item_sk = sa_agg.sr_item_sk
        LEFT JOIN web_agg wa_agg     ON i.i_item_sk = wa_agg.ws_item_sk
        LEFT JOIN call_center cc    ON ca_agg.call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp   ON ca_agg.catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN ship_mode sm      ON ca_agg.ship_mode_sk = sm.sm_ship_mode_sk
        RIGHT JOIN ship_mode sm2   ON ca_agg.ship_mode_sk = sm2.sm_ship_mode_sk
        LEFT JOIN warehouse w      ON ca_agg.warehouse_sk = w.w_warehouse_sk
        LEFT JOIN promotion p      ON ca_agg.promo_sk = p.p_promo_sk
        LEFT JOIN customer_address ca ON ca_agg.bill_addr_sk = ca.ca_address_sk
        LEFT JOIN time_dim td_cs   ON ca_agg.cs_sold_time_sk = td_cs.t_time_sk
        LEFT JOIN web_page wp      ON wa_agg.web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site wsit    ON wa_agg.web_site_sk = wsit.web_site_sk
        LEFT JOIN time_dim td_ws   ON wa_agg.ws_sold_time_sk = td_ws.t_time_sk
        LEFT JOIN customer_address ca_ret ON sa_agg.return_addr_sk = ca_ret.ca_address_sk
        LEFT JOIN customer_demographics cd_ret ON sa_agg.return_cdemo_sk = cd_ret.cd_demo_sk
        LEFT JOIN household_demographics hd_ret ON sa_agg.return_hdemo_sk = hd_ret.hd_demo_sk
        LEFT JOIN time_dim td_ret   ON sa_agg.sr_return_time_sk = td_ret.t_time_sk
        LEFT JOIN inventory inv     ON i.i_item_sk = inv.inv_item_sk AND w.w_warehouse_sk = inv.inv_warehouse_sk
    ),
    with_running AS (
        SELECT
            j.*, 
            SUM(j.catalog_net_paid + j.web_net_paid + j.return_amt) OVER (
                PARTITION BY j.i_item_id ORDER BY j.sale_hour
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_net_sales
        FROM joined j
    )
SELECT
    i_item_id,
    i_product_name,
    call_center_name,
    cp_department,
    ship_mode_type,
    warehouse_name,
    promo_name,
    bill_city,
    sale_hour,
    SUM(catalog_net_paid) AS total_catalog_sales,
    SUM(web_net_paid)     AS total_web_sales,
    SUM(return_amt)       AS total_returns,
    MAX(running_net_sales) AS running_net_sales,
    LAG(MAX(running_net_sales)) OVER (
        PARTITION BY i_item_id ORDER BY sale_hour
    ) AS lag_running_net_sales
FROM with_running
GROUP BY
    i_item_id,
    i_product_name,
    call_center_name,
    cp_department,
    ship_mode_type,
    warehouse_name,
    promo_name,
    bill_city,
    sale_hour
ORDER BY
    total_catalog_sales DESC,
    i_item_id
LIMIT 100
