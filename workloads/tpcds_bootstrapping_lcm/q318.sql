SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_current_year,
    d.d_quarter_name,
    COALESCE(sr_agg.store_net_loss, 0)        AS store_net_loss,
    COALESCE(wr_agg.web_net_loss, 0)         AS web_net_loss,
    COALESCE(sr_agg.store_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0) AS total_net_loss,
    COALESCE(sr_agg.store_return_cnt, 0)    AS store_return_cnt,
    COALESCE(wr_agg.web_return_cnt, 0)      AS web_return_cnt,
    COALESCE(sr_agg.avg_store_return_qty, 0) AS avg_store_return_qty,
    COALESCE(wr_agg.avg_web_return_qty, 0)   AS avg_web_return_qty,
    RANK() OVER (
        PARTITION BY d.d_current_year, d.d_quarter_name
        ORDER BY COALESCE(sr_agg.store_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0) DESC
    )                                        AS loss_rank
FROM store s
JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss)               AS store_net_loss,
        COUNT(*)                          AS store_return_cnt,
        AVG(sr.sr_return_quantity)       AS avg_store_return_qty
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
) sr_agg
    ON sr_agg.sr_store_sk = s.s_store_sk
   AND sr_agg.sr_returned_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss)              AS web_net_loss,
        COUNT(*)                         AS web_return_cnt,
        AVG(wr.wr_return_quantity)       AS avg_web_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
) wr_agg
    ON wr_agg.wr_returned_date_sk = d.d_date_sk
WHERE d.d_current_year = '2022'
  AND d.d_quarter_name = 'Q1'
ORDER BY total_net_loss DESC
LIMIT 100
