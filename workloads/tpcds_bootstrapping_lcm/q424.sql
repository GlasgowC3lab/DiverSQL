SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY agg.return_year ORDER BY agg.total_return_amount DESC) AS rank_by_return_amount_year
FROM (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        cc.cc_state AS call_center_state,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d_wr.d_year AS return_year,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_transactions
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_wr.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_wr.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE d_wr.d_year BETWEEN 2000 AND 2005
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_wr.d_year,
        hd_ret.hd_buy_potential,
        hd_ref.hd_buy_potential
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
