WITH sr_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS store_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
),
cr_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    sr_agg.store_return_cnt,
    sr_agg.store_net_loss,
    COALESCE(cr_agg.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(cr_agg.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wr_agg.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(wr_agg.web_net_loss, 0) AS web_net_loss,
    d_closed.d_year AS store_closed_year,
    d_closed.d_month_seq AS store_closed_month,
    (COALESCE(sr_agg.store_net_loss, 0) + COALESCE(cr_agg.catalog_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0)) AS total_net_loss
FROM sr_agg
JOIN date_dim d ON sr_agg.date_sk = d.d_date_sk
JOIN store s ON sr_agg.store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN cr_agg ON cr_agg.date_sk = d.d_date_sk
LEFT JOIN wr_agg ON wr_agg.date_sk = d.d_date_sk
WHERE (COALESCE(sr_agg.store_net_loss, 0) + COALESCE(cr_agg.catalog_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0)) > 0
ORDER BY total_net_loss DESC, d.d_year DESC, d.d_month_seq DESC, s.s_store_id
