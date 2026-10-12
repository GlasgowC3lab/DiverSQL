WITH agg_ws AS (
    SELECT
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS cnt_sales
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
      AND ws.ws_sales_price > 50
    GROUP BY ws.ws_ship_mode_sk
),
combined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cc.cc_state,
        sm.sm_type,
        r.r_reason_desc,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        aw.total_profit,
        aw.cnt_sales,
        wp.wp_type AS web_page_type,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS rn_state
    FROM catalog_returns cr
    JOIN call_center cc                ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                  ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON cr.cr_warehouse_sk   = w.w_warehouse_sk
    JOIN reason r                     ON cr.cr_reason_sk      = r.r_reason_sk
    JOIN customer c                   ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd     ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp                  ON wp.wp_customer_sk = c.c_customer_sk
    JOIN agg_ws aw                    ON sm.sm_ship_mode_sk = aw.ws_ship_mode_sk
    WHERE r.r_reason_desc LIKE '%service%'
      AND cc.cc_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND NOT EXISTS (
          SELECT 1 FROM web_sales ws2 WHERE ws2.ws_order_number = cr.cr_order_number
      )
    UNION
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cc.cc_state,
        sm.sm_type,
        r.r_reason_desc,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        aw.total_profit,
        aw.cnt_sales,
        wp.wp_type AS web_page_type,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS rn_state
    FROM catalog_returns cr
    JOIN call_center cc                ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                  ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON cr.cr_warehouse_sk   = w.w_warehouse_sk
    JOIN reason r                     ON cr.cr_reason_sk      = r.r_reason_sk
    JOIN customer c                   ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd     ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp                  ON wp.wp_customer_sk = c.c_customer_sk
    JOIN agg_ws aw                    ON sm.sm_ship_mode_sk = aw.ws_ship_mode_sk
    WHERE r.r_reason_desc LIKE '%warranty%'
      AND cc.cc_state = 'TX'
      AND cd.cd_credit_rating = 'Low Risk'
      AND NOT EXISTS (
          SELECT 1 FROM web_sales ws2 WHERE ws2.ws_order_number = cr.cr_order_number
      )
)
SELECT
    cr_order_number,
    cr_return_amount,
    cc_state,
    sm_type,
    r_reason_desc,
    cd_credit_rating,
    hd_buy_potential,
    total_profit,
    cnt_sales,
    web_page_type,
    rn_state,
    RANK() OVER (PARTITION BY cc_state ORDER BY cr_return_amount DESC) AS return_rank,
    CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM combined
WHERE rn_state <= 5
ORDER BY cc_state, return_rank
