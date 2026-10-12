WITH site_dates AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d_open.d_date_sk AS open_sk,
        d_close.d_date_sk AS close_sk
    FROM web_site ws
    JOIN date_dim d_open
        ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_open.d_date <= d_close.d_date
),
site_returns AS (
    SELECT
        sd.web_site_id,
        sd.web_name,
        d_ret.d_date,
        d_ret.d_date_sk,
        wr.wr_net_loss
    FROM site_dates sd
    JOIN web_returns wr
        ON wr.wr_returned_date_sk BETWEEN sd.open_sk AND sd.close_sk
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2022
),
site_aggregates AS (
    SELECT
        web_site_id,
        web_name,
        SUM(wr_net_loss) AS total_net_loss
    FROM site_returns
    GROUP BY web_site_id, web_name
)
SELECT
    sr.web_site_id,
    sr.web_name,
    sr.d_date,
    SUM(sr.wr_net_loss) OVER (PARTITION BY sr.web_site_id ORDER BY sr.d_date_sk) AS cumulative_net_loss,
    sa.total_net_loss,
    DENSE_RANK() OVER (ORDER BY sa.total_net_loss DESC) AS net_loss_rank
FROM site_returns sr
JOIN site_aggregates sa
    ON sr.web_site_id = sa.web_site_id
ORDER BY net_loss_rank, sr.web_site_id, sr.d_date
