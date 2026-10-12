SELECT
    sub.return_date,
    sub.day_name,
    sub.hour_of_day,
    sub.minute_of_hour,
    sub.store_name,
    sub.state,
    sub.promo_name,
    sub.discount_active,
    sub.promo_end_date,
    sub.total_return_amount,
    sub.total_return_tax,
    sub.total_net_loss,
    sub.return_count,
    ROW_NUMBER() OVER (PARTITION BY sub.state ORDER BY sub.total_return_amount DESC) AS state_return_rank
FROM (
    SELECT
        dr.d_date AS return_date,
        dr.d_day_name AS day_name,
        td.t_hour AS hour_of_day,
        td.t_minute AS minute_of_hour,
        s.s_store_name AS store_name,
        s.s_state AS state,
        p.p_promo_name AS promo_name,
        p.p_discount_active AS discount_active,
        d_end.d_date AS promo_end_date,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    GROUP BY
        dr.d_date,
        dr.d_day_name,
        td.t_hour,
        td.t_minute,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        p.p_discount_active,
        d_end.d_date
) sub
ORDER BY sub.total_return_amount DESC
LIMIT 100
