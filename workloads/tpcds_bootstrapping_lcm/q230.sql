WITH agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        d_return.d_year,
        d_cc_closed.d_date AS cc_closed_date,
        d_return.d_date AS return_date,
        DATE_DIFF('day', d_cc_closed.d_date, d_return.d_date) AS days_between,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        d_return.d_year,
        d_cc_closed.d_date,
        d_return.d_date
)
SELECT
    agg.cc_call_center_sk,
    agg.cc_name,
    agg.s_store_sk,
    agg.s_store_name,
    agg.d_year,
    agg.days_between,
    agg.total_net_loss,
    agg.total_return_amount,
    agg.total_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY agg.cc_call_center_sk ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
