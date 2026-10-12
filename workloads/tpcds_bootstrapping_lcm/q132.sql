WITH returns_agg AS (
    SELECT
        s.s_store_name,
        s.s_city,
        cc.cc_call_center_id,
        i.i_category,
        d_ret.d_year,
        d_ret.d_month_seq,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_quantity) AS total_quantity,
        date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_operational_days,
        ROW_NUMBER() OVER (PARTITION BY d_ret.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS rank_by_year
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        s.s_store_name,
        s.s_city,
        cc.cc_call_center_id,
        i.i_category,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_cc_open.d_date,
        d_cc_closed.d_date
)
SELECT *
FROM returns_agg
WHERE rank_by_year <= 5
ORDER BY d_year, rank_by_year
