WITH joined_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        sm_ws.sm_ship_mode_id AS ws_ship_mode,
        sm_cr.sm_ship_mode_id AS cr_ship_mode,
        d_ss_sold.d_year,
        t_ss_sold.t_hour,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_return_amount) - SUM(wr.wr_return_amt)) AS total_profit
    FROM store_sales ss
    JOIN date_dim d_ss_sold ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
    JOIN time_dim t_ss_sold ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_ss_store_closed ON s.s_closed_date_sk = d_ss_store_closed.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_ss_sold.d_date_sk
                     AND ws.ws_sold_time_sk = t_ss_sold.t_time_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN catalog_returns cr ON 1 = 1
    JOIN date_dim d_cr_ret ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
    JOIN time_dim t_cr_ret ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                       AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr_ret ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    JOIN time_dim t_wr_ret ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    WHERE d_ss_sold.d_year = 2000
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        sm_ws.sm_ship_mode_id,
        sm_cr.sm_ship_mode_id,
        d_ss_sold.d_year,
        t_ss_sold.t_hour
)
SELECT
    jd.s_store_sk,
    jd.s_store_name,
    jd.ws_ship_mode,
    jd.cr_ship_mode,
    jd.d_year,
    jd.t_hour,
    jd.store_sales_net_paid,
    jd.web_sales_net_paid,
    jd.catalog_return_amount,
    jd.web_return_amount,
    jd.total_profit,
    jd.rn
FROM (
    SELECT
        jd.*, 
        ROW_NUMBER() OVER (PARTITION BY jd.s_store_sk ORDER BY jd.total_profit DESC) AS rn,
        tn.top_n
    FROM joined_data jd
    CROSS JOIN (SELECT 3 AS top_n) tn
) jd
WHERE jd.rn <= jd.top_n
ORDER BY jd.s_store_sk, jd.rn
