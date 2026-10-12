WITH agg AS (
    SELECT
        s.s_store_name,
        s.s_state,
        cc.cc_name,
        cc.cc_state,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_name,
        s.s_state,
        cc.cc_name,
        cc.cc_state,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq
)
SELECT
    agg.s_store_name,
    agg.s_state,
    agg.cc_name,
    agg.cc_state,
    agg.p_promo_name,
    agg.d_year,
    agg.d_month_seq,
    agg.total_return_amount,
    agg.total_return_tax,
    agg.distinct_orders,
    agg.avg_return_quantity,
    RANK() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_return_amount DESC) AS store_return_rank
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
