WITH base_join AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_return_amt_inc_tax AS sr_return_amt_inc_tax,
        sr.sr_net_loss AS sr_net_loss,
        r.r_reason_desc,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour,
        cr.cr_return_amt_inc_tax AS cr_return_amt_inc_tax,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_return_amt_inc_tax AS wr_return_amt_inc_tax,
        wr.wr_net_loss AS wr_net_loss
    FROM store_returns AS sr
    FULL OUTER JOIN reason AS r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim AS d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim AS t
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns AS cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns AS wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1211
        AND t.t_hour BETWEEN 9 AND 17
        AND r.r_reason_desc LIKE '%damage%'
        AND sr.sr_return_amt_inc_tax > 1000
        AND cr.cr_return_amt_inc_tax > 500
        AND wr.wr_return_tax > 10
),
agg_per_reason AS (
    SELECT
        r_reason_desc,
        d_quarter_seq,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
        SUM(COALESCE(sr_return_amt_inc_tax, 0) + COALESCE(cr_return_amt_inc_tax, 0) + COALESCE(wr_return_amt_inc_tax, 0)) AS total_return_amount
    FROM base_join
    GROUP BY r_reason_desc, d_quarter_seq
)
SELECT
    d_quarter_seq,
    AVG(total_net_loss) AS avg_net_loss,
    COUNT(*) AS reason_count
FROM agg_per_reason
WHERE total_return_amount > 2000
GROUP BY d_quarter_seq
HAVING AVG(total_net_loss) > 5000
ORDER BY avg_net_loss DESC
