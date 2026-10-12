WITH return_stats AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        s.s_city,
        i.i_category,
        i.i_brand,
        COUNT(DISTINCT w.wr_order_number) AS order_count,
        SUM(w.wr_return_amt) AS total_return_amt,
        SUM(w.wr_return_quantity) AS total_qty,
        SUM(w.wr_net_loss) AS total_net_loss,
        AVG(w.wr_net_loss) AS avg_net_loss,
        COUNT(DISTINCT hd_refunded.hd_demo_sk) AS refunded_hh_count,
        COUNT(DISTINCT hd_returning.hd_demo_sk) AS returning_hh_count,
        SUM(CASE WHEN hd_refunded.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_buy_potential_refunded,
        SUM(CASE WHEN hd_returning.hd_buy_potential = 'LOW' THEN 1 ELSE 0 END) AS low_buy_potential_returning
    FROM web_returns w
    JOIN date_dim d ON w.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON w.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded ON w.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON w.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2018 AND 2020
      AND i.i_category IN ('Electronics', 'Furniture')
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        s.s_city,
        i.i_category,
        i.i_brand
    HAVING SUM(w.wr_return_amt) > 500
)
SELECT
    rs.d_year,
    rs.d_quarter_name,
    rs.s_state,
    rs.s_city,
    rs.i_category,
    rs.i_brand,
    rs.order_count,
    rs.total_return_amt,
    rs.total_qty,
    rs.total_net_loss,
    rs.avg_net_loss,
    rs.refunded_hh_count,
    rs.returning_hh_count,
    rs.high_buy_potential_refunded,
    rs.low_buy_potential_returning,
    ROW_NUMBER() OVER (PARTITION BY rs.d_year ORDER BY rs.total_return_amt DESC) AS rank_by_year
FROM return_stats rs
ORDER BY rs.d_year, rs.total_return_amt DESC
LIMIT 200
