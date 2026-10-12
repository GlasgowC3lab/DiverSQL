WITH first_part AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        ws.ws_order_number,
        ws.ws_net_paid,
        LAG(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS prev_net_paid,
        LEAD(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS next_net_paid,
        SUM(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
        RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS net_paid_rank
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_return_time_sk = t.t_time_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
                               AND sr.sr_store_sk = s.s_store_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_returned_time_sk = t.t_time_sk
                              AND wr.wr_refunded_customer_sk = c.c_customer_sk
                              AND wr.wr_returning_customer_sk = c.c_customer_sk
                              AND wr.wr_item_sk = ws.ws_item_sk
                              AND wr.wr_order_number = ws.ws_order_number
    WHERE
        d.d_year = 2002
        AND sm.sm_carrier = 'UPS'
        AND t.t_sub_shift = 'morning'
),
second_part AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        ws.ws_order_number,
        ws.ws_net_paid,
        LAG(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS prev_net_paid,
        LEAD(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS next_net_paid,
        SUM(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
        RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS net_paid_rank
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_return_time_sk = t.t_time_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
                               AND sr.sr_store_sk = s.s_store_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_returned_time_sk = t.t_time_sk
                              AND wr.wr_refunded_customer_sk = c.c_customer_sk
                              AND wr.wr_returning_customer_sk = c.c_customer_sk
                              AND wr.wr_item_sk = ws.ws_item_sk
                              AND wr.wr_order_number = ws.ws_order_number
    WHERE
        d.d_year = 2003
        AND sm.sm_carrier = 'AIR'
        AND t.t_sub_shift = 'afternoon'
)
SELECT *
FROM (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
) t
ORDER BY running_net_paid DESC
LIMIT 100
