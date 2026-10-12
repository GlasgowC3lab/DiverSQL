WITH store_ret AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        AVG(sr.sr_return_amt) AS avg_store_return_amt,
        d_closed.d_year AS closed_year,
        d_closed.d_month_seq AS closed_month_seq
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        d_closed.d_year,
        d_closed.d_month_seq
),
web_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
        AVG(wr.wr_return_amt) AS avg_web_return_amt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc
)
SELECT
    sr.d_year,
    sr.d_month_seq,
    sr.s_store_id,
    sr.s_store_name,
    sr.r_reason_desc AS store_reason_desc,
    wr.r_reason_desc AS web_reason_desc,
    sr.store_net_loss,
    wr.web_net_loss,
    sr.store_return_qty,
    wr.web_return_qty,
    sr.store_return_cnt,
    wr.web_return_cnt,
    sr.avg_store_return_amt,
    wr.avg_web_return_amt,
    (sr.store_net_loss + wr.web_net_loss) AS total_net_loss,
    sr.closed_year,
    sr.closed_month_seq,
    ROW_NUMBER() OVER (PARTITION BY sr.d_year, sr.d_month_seq ORDER BY (sr.store_net_loss + wr.web_net_loss) DESC) AS rank_by_total_net_loss
FROM store_ret sr
JOIN web_ret wr
    ON sr.d_year = wr.d_year
   AND sr.d_month_seq = wr.d_month_seq
   AND sr.r_reason_desc = wr.r_reason_desc
WHERE sr.d_year = 2022
ORDER BY total_net_loss DESC
LIMIT 100
