WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_quantity,
        ss_wholesale_cost,
        ss_sales_price,
        ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        i.i_category,
        sm.sm_code,
        ss.ss_net_profit,
        ws.ws_net_profit,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        p.p_cost,
        we.web_state,
        td.t_hour
    FROM ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = i.i_item_sk
                         AND sr.sr_return_time_sk = td.t_time_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                         AND cr.cr_returned_time_sk = td.t_time_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = i.i_item_sk
                       AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
                     AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
                    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE
        i.i_category = 'Electronics'
        AND sm.sm_code = 'AIR'
        AND we.web_state = 'CA'
        AND td.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        i_category,
        sm_code,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(cr_return_quantity) AS total_catalog_return_qty,
        SUM(sr_return_quantity) AS total_store_return_qty,
        AVG(p_cost) AS avg_promo_cost
    FROM joined
    GROUP BY i_category, sm_code
)
SELECT
    i_category,
    sm_code,
    total_store_profit,
    total_web_profit,
    total_catalog_return_qty,
    total_store_return_qty,
    avg_promo_cost,
    SUM(total_store_profit) OVER (
        PARTITION BY i_category
        ORDER BY sm_code
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_store_profit
FROM agg
ORDER BY total_store_profit DESC
LIMIT 100
