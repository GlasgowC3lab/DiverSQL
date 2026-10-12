WITH active_cc AS (
    SELECT cc_call_center_id
    FROM call_center
    WHERE cc_state = 'CA'
),
inactive_cc AS (
    SELECT cc_call_center_id
    FROM call_center
    WHERE cc_state <> 'CA'
),
filtered_cc AS (
    SELECT cc_call_center_id
    FROM active_cc
    EXCEPT
    SELECT cc_call_center_id FROM inactive_cc
),
small_dim AS (
    SELECT 'A' AS grp UNION ALL SELECT 'B' AS grp
),
base AS (
    SELECT
        cc.cc_call_center_id,
        s.s_store_id,
        we.web_site_id,
        cs.cs_net_profit            AS catalog_net_profit,
        ss.ss_net_profit            AS store_net_profit,
        ws.ws_net_profit            AS web_net_profit,
        cr_agg.total_return_loss    AS total_return_loss,
        t1.t_hour,
        ib1.ib_upper_bound
    FROM catalog_sales cs
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN customer_demographics cd1 ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
    JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN income_band ib1 ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN warehouse w1 ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r1 ON cr.cr_reason_sk = r1.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cr2.cr_net_loss) AS total_return_loss
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
    ) AS cr_agg ON TRUE
    JOIN store_sales ss ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t1.t_time_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND we.web_state = 'CA'
      AND ib1.ib_upper_bound > 50000
      AND t1.t_hour BETWEEN 8 AND 12
      AND ws.ws_quantity > 5
)
SELECT
    dim.grp,
    base.cc_call_center_id,
    base.s_store_id,
    base.web_site_id,
    SUM(base.catalog_net_profit)                           AS total_catalog_profit,
    SUM(base.store_net_profit)                             AS total_store_profit,
    SUM(base.web_net_profit)                               AS total_web_profit,
    SUM(base.catalog_net_profit + base.store_net_profit + base.web_net_profit) AS total_profit,
    SUM(base.total_return_loss)                            AS total_return_loss,
    RANK() OVER (ORDER BY SUM(base.catalog_net_profit + base.store_net_profit + base.web_net_profit) DESC) AS profit_rank
FROM base
CROSS JOIN small_dim AS dim
WHERE base.cc_call_center_id IN (SELECT cc_call_center_id FROM filtered_cc)
GROUP BY dim.grp, base.cc_call_center_id, base.s_store_id, base.web_site_id
HAVING SUM(base.catalog_net_profit + base.store_net_profit + base.web_net_profit) > 1000
ORDER BY profit_rank
OFFSET 0
LIMIT 100
