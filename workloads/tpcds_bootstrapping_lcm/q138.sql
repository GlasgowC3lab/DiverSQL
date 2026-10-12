WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_ret.d_date AS return_date,
        d_ship.d_date AS first_ship_date,
        DATE_DIFF('day', d_ship.d_date, d_ret.d_date) AS days_between_ship_and_return,
        c_ret.c_customer_id,
        c_ret.c_first_name,
        c_ret.c_last_name,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_cur.hd_buy_potential AS current_buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c_ret
        ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_cur
        ON c_ret.c_current_hdemo_sk = hd_cur.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ship
        ON c_ret.c_first_shipto_date_sk = d_ship.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_ret.d_date,
        d_ship.d_date,
        c_ret.c_customer_id,
        c_ret.c_first_name,
        c_ret.c_last_name,
        hd_ret.hd_buy_potential,
        hd_cur.hd_buy_potential
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.return_date,
    a.first_ship_date,
    a.days_between_ship_and_return,
    a.c_customer_id,
    a.c_first_name,
    a.c_last_name,
    a.returning_buy_potential,
    a.current_buy_potential,
    a.total_return_amount,
    a.total_net_loss,
    a.return_count,
    a.avg_return_quantity,
    RANK() OVER (PARTITION BY a.s_store_id ORDER BY a.total_return_amount DESC) AS store_return_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
