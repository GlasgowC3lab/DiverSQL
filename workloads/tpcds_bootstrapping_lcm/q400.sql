WITH store_ret_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txns,
        SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_txns,
        SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    dr.d_date AS return_date,
    dr.d_year,
    dr.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    p_start.p_promo_name AS promo_start_name,
    p_end.p_promo_name AS promo_end_name,
    COALESCE(sr_agg.total_store_return_amt, 0) AS total_store_return_amt,
    COALESCE(sr_agg.total_store_return_qty, 0) AS total_store_return_qty,
    COALESCE(wr_agg.total_web_return_amt, 0) AS total_web_return_amt,
    COALESCE(wr_agg.total_web_return_qty, 0) AS total_web_return_qty,
    COALESCE(sr_agg.total_store_return_amt, 0) - COALESCE(wr_agg.total_web_return_amt, 0) AS return_amt_diff,
    COALESCE(sr_agg.store_return_txns, 0) AS store_return_txns,
    COALESCE(wr_agg.web_return_txns, 0) AS web_return_txns,
    d_closed.d_date AS store_closed_date,
    CASE WHEN d_closed.d_date IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status_on_return_date,
    p_start.p_discount_active AS promo_start_discount_active,
    p_end.p_discount_active AS promo_end_discount_active,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY dr.d_date DESC) AS store_return_rank_desc
FROM
    date_dim dr
    LEFT JOIN store_ret_agg sr_agg
        ON sr_agg.sr_returned_date_sk = dr.d_date_sk
    LEFT JOIN store s
        ON sr_agg.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_ret_agg wr_agg
        ON wr_agg.wr_returned_date_sk = dr.d_date_sk
    LEFT JOIN promotion p_start
        ON p_start.p_start_date_sk = dr.d_date_sk
    LEFT JOIN promotion p_end
        ON p_end.p_end_date_sk = dr.d_date_sk
WHERE
    dr.d_year = 2022
ORDER BY
    dr.d_date DESC,
    total_store_return_amt DESC
LIMIT 100
