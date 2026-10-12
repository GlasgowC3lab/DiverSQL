WITH daily_store_returns AS (
    SELECT
        d.d_date,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_market_manager,
        s.s_state,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS return_order_cnt
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_date,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_market_manager,
        s.s_state
)
SELECT
    dr.d_date,
    dr.s_store_id,
    dr.s_market_manager,
    dr.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    p.p_response_target,
    ws.web_name,
    ws.web_city,
    d_close.d_date AS web_close_date,
    dr.total_return_amt,
    dr.total_return_tax,
    dr.total_net_loss,
    dr.return_order_cnt,
    ROW_NUMBER() OVER (PARTITION BY dr.d_date ORDER BY dr.total_return_amt DESC) AS store_return_rank
FROM daily_store_returns dr
JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = dr.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
WHERE p.p_end_date_sk = dr.d_date_sk
ORDER BY dr.d_date DESC, dr.total_return_amt DESC
LIMIT 200
