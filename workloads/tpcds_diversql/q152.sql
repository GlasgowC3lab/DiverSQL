WITH joined AS (
    SELECT
        d.d_year,
        s.s_division_name,
        sm.sm_type AS ship_mode_type,
        p.p_promo_name,
        r.r_reason_desc,
        ws.ws_net_profit,
        sr.sr_net_loss,
        ws.ws_quantity,
        sr.sr_return_quantity,
        ws.ws_ext_sales_price,
        sr.sr_return_amt
    FROM
        store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_sales ws TABLESAMPLE BERNOULLI (10) ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = i.i_item_sk
            AND wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_returned_time_sk = t.t_time_sk
            AND wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1999 AND 2001
        AND s.s_number_employees > 250
        AND ca.ca_gmt_offset = -5.00
        AND sm.sm_type = 'AIR'
        AND r.r_reason_desc LIKE '%damaged%'
        AND cc.cc_state = 'CA'
)
SELECT
    d_year,
    s_division_name,
    ship_mode_type,
    p_promo_name,
    r_reason_desc,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(sr_net_loss) AS total_store_loss,
    SUM(ws_quantity) AS total_web_qty,
    SUM(sr_return_quantity) AS total_store_ret_qty,
    AVG(ws_ext_sales_price) AS avg_web_sales_price,
    AVG(sr_return_amt) AS avg_store_return_amt
FROM joined
GROUP BY
    d_year,
    s_division_name,
    ship_mode_type,
    p_promo_name,
    r_reason_desc
HAVING
    SUM(ws_net_profit) > 10000
ORDER BY
    total_web_profit DESC,
    d_year
LIMIT 100
