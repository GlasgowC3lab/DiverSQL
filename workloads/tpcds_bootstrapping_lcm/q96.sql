WITH base AS (
    SELECT
        dr_ret.d_year AS return_year,
        dr_ret.d_month_seq AS return_month,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_state AS refunded_state,
        s.s_state AS store_state,
        ws.web_state AS web_state,
        ws.web_name AS website_name,
        ws.web_tax_percentage AS ws_tax_percentage,
        s.s_floor_space AS s_floor_space,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        wr.wr_order_number AS order_number,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_fee AS fee,
        CASE WHEN ca_ret.ca_state = ca_ref.ca_state THEN 1 ELSE 0 END AS same_state_flag
    FROM web_returns wr
    JOIN date_dim dr_ret
        ON wr.wr_returned_date_sk = dr_ret.d_date_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = dr_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = dr_ret.d_date_sk
    JOIN date_dim dr_close
        ON ws.web_close_date_sk = dr_close.d_date_sk
    WHERE dr_ret.d_year BETWEEN 2000 AND 2010
),
aggregated AS (
    SELECT
        return_year,
        return_month,
        returning_state,
        refunded_state,
        store_state,
        web_state,
        website_name,
        COUNT(DISTINCT order_number) AS distinct_orders,
        SUM(return_amt) AS total_return_amt,
        SUM(net_loss) AS total_net_loss,
        AVG(return_quantity) AS avg_return_qty,
        SUM(return_amt) - SUM(fee) AS net_return_minus_fees,
        SUM(CASE WHEN same_state_flag = 1 THEN net_loss ELSE 0 END) AS net_loss_same_state,
        AVG(s_floor_space) AS avg_floor_space,
        AVG(ws_tax_percentage) AS avg_website_tax_percentage
    FROM base
    GROUP BY
        return_year,
        return_month,
        returning_state,
        refunded_state,
        store_state,
        web_state,
        website_name
    HAVING SUM(return_amt) > 0
)
SELECT
    ag.return_year,
    ag.return_month,
    ag.returning_state,
    ag.refunded_state,
    ag.store_state,
    ag.web_state,
    ag.website_name,
    ag.distinct_orders,
    ag.total_return_amt,
    ag.total_net_loss,
    ag.avg_return_qty,
    ag.net_return_minus_fees,
    ag.net_loss_same_state,
    ag.avg_floor_space,
    ag.avg_website_tax_percentage,
    ROW_NUMBER() OVER (PARTITION BY ag.return_year ORDER BY ag.total_net_loss DESC) AS loss_rank_by_year,
    SUM(ag.total_net_loss) OVER (PARTITION BY ag.return_year ORDER BY ag.return_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss_by_month
FROM aggregated ag
ORDER BY ag.total_net_loss DESC
LIMIT 20
