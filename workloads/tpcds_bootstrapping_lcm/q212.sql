SELECT
    store_name,
    city,
    state,
    return_year,
    total_return_amount,
    total_net_loss,
    num_returns,
    RANK() OVER (PARTITION BY return_year ORDER BY total_return_amount DESC) AS store_year_rank
FROM (
    SELECT
        s.s_store_name AS store_name,
        s.s_city AS city,
        s.s_state AS state,
        d.d_year AS return_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY s.s_store_name, s.s_city, s.s_state, d.d_year
) t
ORDER BY return_year, store_year_rank
LIMIT 100
