WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS total_returns
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND sm.sm_type = 'AIR'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        sm.sm_type
    HAVING SUM(cr.cr_net_loss) > 10000
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.cc_name,
    agg.cc_city,
    agg.s_store_name,
    agg.s_city,
    agg.sm_type,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.avg_return_quantity,
    agg.total_returns,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year, agg.d_month_seq ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY agg.d_year, agg.d_month_seq, agg.total_net_loss DESC
LIMIT 100
