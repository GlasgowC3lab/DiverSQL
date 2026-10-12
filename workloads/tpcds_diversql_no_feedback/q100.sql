WITH agg_ws AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        d_ws.d_year,
        SUM(ws.ws_net_paid)        AS total_net_paid,
        SUM(ws.ws_net_profit)      AS total_net_profit,
        COUNT(*)                  AS ws_cnt
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    GROUP BY ws.ws_warehouse_sk, ws.ws_promo_sk, d_ws.d_year
)
SELECT
    w.w_warehouse_name,
    p.p_promo_name,
    d_year.d_year,
    SUM(aw.total_net_paid)        AS sum_net_paid,
    SUM(aw.total_net_profit)      AS sum_net_profit,
    SUM(cr.cr_net_loss)           AS sum_catalog_return_loss,
    SUM(wr.wr_net_loss)           AS sum_web_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT wr.wr_return_quantity) AS web_return_qty_cnt
FROM agg_ws aw
JOIN warehouse w            ON aw.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p            ON aw.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_year        ON aw.d_year = d_year.d_year

-- Catalog Returns and its related dimensions
JOIN catalog_returns cr      ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_cr           ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr           ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN catalog_page cp         ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r_cr             ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer_address ca_refund_cr ON cr.cr_refunded_addr_sk = ca_refund_cr.ca_address_sk
JOIN customer_address ca_return_cr ON cr.cr_returning_addr_sk = ca_return_cr.ca_address_sk
JOIN customer_demographics cd_refund_cr ON cr.cr_refunded_cdemo_sk = cd_refund_cr.cd_demo_sk
JOIN customer_demographics cd_return_cr ON cr.cr_returning_cdemo_sk = cd_return_cr.cd_demo_sk
JOIN household_demographics hd_refund_cr ON cr.cr_refunded_hdemo_sk = hd_refund_cr.hd_demo_sk
JOIN household_demographics hd_return_cr ON cr.cr_returning_hdemo_sk = hd_return_cr.hd_demo_sk
JOIN date_dim d_cp_start     ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end       ON cp.cp_end_date_sk   = d_cp_end.d_date_sk

-- Original Web Sales (needed for Web Returns)
JOIN web_sales ws_orig       ON ws_orig.ws_order_number = cr.cr_order_number
JOIN date_dim d_ws_orig       ON ws_orig.ws_sold_date_sk = d_ws_orig.d_date_sk
JOIN time_dim t_ws_orig       ON ws_orig.ws_sold_time_sk = t_ws_orig.t_time_sk
JOIN web_page wp             ON ws_orig.ws_web_page_sk = wp.wp_web_page_sk

-- Web Returns and its related dimensions
JOIN web_returns wr         ON wr.wr_item_sk = ws_orig.ws_item_sk
                               AND wr.wr_order_number = ws_orig.ws_order_number
JOIN date_dim d_wr           ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr           ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr             ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer_address ca_refund_wr ON wr.wr_refunded_addr_sk = ca_refund_wr.ca_address_sk
JOIN customer_address ca_return_wr ON wr.wr_returning_addr_sk = ca_return_wr.ca_address_sk
JOIN customer_demographics cd_refund_wr ON wr.wr_refunded_cdemo_sk = cd_refund_wr.cd_demo_sk
JOIN customer_demographics cd_return_wr ON wr.wr_returning_cdemo_sk = cd_return_wr.cd_demo_sk
JOIN household_demographics hd_refund_wr ON wr.wr_refunded_hdemo_sk = hd_refund_wr.hd_demo_sk
JOIN household_demographics hd_return_wr ON wr.wr_returning_hdemo_sk = hd_return_wr.hd_demo_sk

WHERE
    d_year.d_year = 2001
    AND w.w_country = 'United States'
    AND p.p_discount_active = 'Y'
    AND aw.total_net_paid > (
        SELECT SUM(ws_sub.ws_net_paid)
        FROM web_sales ws_sub
        JOIN date_dim d_sub ON ws_sub.ws_sold_date_sk = d_sub.d_date_sk
        WHERE d_sub.d_year = 2000
    )
GROUP BY w.w_warehouse_name, p.p_promo_name, d_year.d_year
ORDER BY sum_net_paid DESC
LIMIT 100
