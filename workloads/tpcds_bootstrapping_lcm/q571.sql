WITH agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_store_name,
        s.s_number_employees,
        ws.web_site_sk,
        ws.web_state,
        ws.web_country,
        ws.web_tax_percentage,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(sr.sr_fee) AS total_store_fee,
        SUM(sr.sr_return_ship_cost) AS total_store_ship_cost,
        SUM(sr.sr_return_tax) AS total_store_tax,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_ticket_cnt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(wr.wr_fee) AS total_web_fee,
        SUM(wr.wr_return_ship_cost) AS total_web_ship_cost,
        SUM(wr.wr_return_tax) AS total_web_tax,
        COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
        date_diff('day', d_store_closed.d_date, d_ret.d_date) AS days_since_store_closed,
        date_diff('day', d_ret.d_date, d_ws_close.d_date) AS days_until_web_site_closed
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_store_name,
        s.s_number_employees,
        ws.web_site_sk,
        ws.web_state,
        ws.web_country,
        ws.web_tax_percentage,
        d_store_closed.d_date,
        d_ws_close.d_date,
        d_ret.d_date
)

SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_sk,
    a.s_state,
    a.s_city,
    a.s_store_name,
    a.s_number_employees,
    a.web_site_sk,
    a.web_state,
    a.web_country,
    a.web_tax_percentage,
    a.total_store_return_amt,
    a.total_store_return_qty,
    a.total_store_net_loss,
    a.total_store_fee,
    a.total_store_ship_cost,
    a.total_store_tax,
    a.store_ticket_cnt,
    a.total_web_return_amt,
    a.total_web_return_qty,
    a.total_web_net_loss,
    a.total_web_fee,
    a.total_web_ship_cost,
    a.total_web_tax,
    a.web_order_cnt,
    CASE
        WHEN a.total_store_return_amt > 0 THEN a.total_web_return_amt / a.total_store_return_amt
        ELSE NULL
    END AS web_to_store_return_amt_ratio,
    a.days_since_store_closed,
    a.days_until_web_site_closed,
    a.total_store_net_loss / NULLIF(a.s_number_employees, 0) AS net_loss_per_employee,
    SUM(a.total_store_return_amt) OVER (
        PARTITION BY a.s_state
        ORDER BY a.d_year, a.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_store_return_amt_by_state,
    ROW_NUMBER() OVER (
        PARTITION BY a.s_state
        ORDER BY a.total_store_return_amt DESC
    ) AS store_return_rank_in_state
FROM agg a
ORDER BY a.d_year, a.d_month_seq, a.s_state, a.s_city, a.s_store_name
LIMIT 100
