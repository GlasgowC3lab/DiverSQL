WITH aggregated_returns AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        d_ret.d_day_name AS return_day_name,
        t_ret.t_hour AS return_hour,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM store s
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
        AND wr.wr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
      AND (d_closed.d_date_sk IS NULL OR d_ret.d_date_sk < d_closed.d_date_sk)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_day_name,
        t_ret.t_hour
)
SELECT
    store_id,
    store_name,
    return_year,
    return_month_seq,
    return_day_name,
    return_hour,
    store_net_loss,
    web_net_loss,
    store_net_loss + web_net_loss AS total_net_loss,
    store_return_cnt,
    web_return_cnt,
    ROW_NUMBER() OVER (ORDER BY (store_net_loss + web_net_loss) DESC) AS rank
FROM aggregated_returns
ORDER BY total_net_loss DESC
LIMIT 50
