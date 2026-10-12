WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(sr.sr_ticket_number) AS store_return_cnt,
        SUM(sr.sr_return_amt) AS store_return_amt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_date_sk, d.d_year, d.d_month_seq, d.d_quarter_seq
),
wr_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(wr.wr_order_number) AS web_return_cnt,
        SUM(wr.wr_return_amt) AS web_return_amt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_year, d.d_month_seq, d.d_quarter_seq
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    sr_agg.d_year,
    sr_agg.d_month_seq,
    sr_agg.d_quarter_seq,
    sr_agg.store_net_loss,
    wr_agg.web_net_loss,
    (sr_agg.store_net_loss + wr_agg.web_net_loss) AS total_net_loss,
    sr_agg.store_return_cnt,
    wr_agg.web_return_cnt,
    sr_agg.store_return_amt,
    wr_agg.web_return_amt,
    d_closed.d_date AS store_closed_date,
    RANK() OVER (PARTITION BY sr_agg.d_year ORDER BY (sr_agg.store_net_loss + wr_agg.web_net_loss) DESC) AS yearly_rank
FROM store s
JOIN sr_agg
    ON s.s_store_sk = sr_agg.sr_store_sk
JOIN wr_agg
    ON sr_agg.d_date_sk = wr_agg.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE sr_agg.d_year BETWEEN 2020 AND 2022
ORDER BY sr_agg.d_year DESC, total_net_loss DESC
LIMIT 200
