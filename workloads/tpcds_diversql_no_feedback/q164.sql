/* Goal: Identify the most profitable product categories per year, broken down by store state and return reason, using data from all TPC‑DS tables. The query joins every selected table via the allowed surrogate‑key relationships, filters on several business criteria, aggregates with a CUBE, classifies profit levels with a CASE expression, ranks categories per year with a window function, and returns the top 100 rows. */
WITH joined AS (
    SELECT
        d_cs.d_year               AS year,
        i.i_category              AS category,
        s.s_state                 AS state,
        r.r_reason_desc           AS return_reason,
        cs.cs_net_paid            AS net_paid,
        cs.cs_net_profit          AS net_profit,
        cs.cs_order_number        AS order_number,
        cr.cr_return_amount       AS return_amount,
        sr.sr_return_amt          AS store_return_amount,
        ws.ws_net_paid            AS web_net_paid,
        ws.ws_net_profit          AS web_net_profit,
        inv.inv_quantity_on_hand  AS on_hand_qty,
        CASE WHEN cs.cs_net_profit > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
    FROM catalog_sales      cs
    JOIN date_dim          d_cs   ON cs.cs_sold_date_sk   = d_cs.d_date_sk
    JOIN time_dim          t_cs   ON cs.cs_sold_time_sk   = t_cs.t_time_sk
    JOIN item              i      ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page      cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode         sm     ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN catalog_returns   cr     ON cs.cs_order_number   = cr.cr_order_number
                                 AND cs.cs_item_sk       = cr.cr_item_sk
    JOIN date_dim          d_cr   ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim          t_cr   ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN reason            r      ON cr.cr_reason_sk      = r.r_reason_sk
    JOIN store_sales       ss     ON ss.ss_item_sk        = i.i_item_sk
    JOIN date_dim          d_ss   ON ss.ss_sold_date_sk   = d_ss.d_date_sk
    JOIN time_dim          t_ss   ON ss.ss_sold_time_sk   = t_ss.t_time_sk
    JOIN store             s      ON ss.ss_store_sk       = s.s_store_sk
    JOIN store_returns     sr     ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim          d_sr   ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim          t_sr   ON sr.sr_return_time_sk   = t_sr.t_time_sk
    JOIN reason            r_sr   ON sr.sr_reason_sk        = r_sr.r_reason_sk
    JOIN web_sales         ws     ON ws.ws_item_sk          = i.i_item_sk
    JOIN date_dim          d_ws   ON ws.ws_sold_date_sk    = d_ws.d_date_sk
    JOIN time_dim          t_ws   ON ws.ws_sold_time_sk    = t_ws.t_time_sk
    JOIN ship_mode         sm_ws  ON ws.ws_ship_mode_sk    = sm_ws.sm_ship_mode_sk
    JOIN web_page          wp     ON ws.ws_web_page_sk      = wp.wp_web_page_sk
    JOIN date_dim          d_wp_c ON wp.wp_creation_date_sk = d_wp_c.d_date_sk
    JOIN date_dim          d_wp_a ON wp.wp_access_date_sk   = d_wp_a.d_date_sk
    JOIN web_site          we     ON ws.ws_web_site_sk      = we.web_site_sk
    JOIN date_dim          d_we_o ON we.web_open_date_sk   = d_we_o.d_date_sk
    JOIN date_dim          d_we_c ON we.web_close_date_sk  = d_we_c.d_date_sk
    JOIN inventory         inv    ON inv.inv_item_sk        = i.i_item_sk
    JOIN date_dim          d_inv  ON inv.inv_date_sk        = d_inv.d_date_sk
    WHERE d_cs.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND s.s_state = 'CA'
      AND r.r_reason_id = 'AAAAAAAAIAAAAAAA'
      AND sm.sm_type = 'AIR'
      AND ws.ws_quantity > 5
      AND inv.inv_quantity_on_hand > 0
),
agg AS (
    SELECT
        year,
        category,
        state,
        return_reason,
        SUM(net_paid)   AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        COUNT(DISTINCT order_number) AS orders_cnt,
        CASE WHEN SUM(net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM joined
    GROUP BY CUBE (year, category, state, return_reason)
),
final AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank
    FROM agg
)
SELECT
    year,
    category,
    state,
    return_reason,
    total_net_paid,
    total_net_profit,
    orders_cnt,
    profit_level,
    profit_rank
FROM final
ORDER BY year DESC, profit_rank ASC
LIMIT 100
