WITH catalog_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        s.s_store_id,
        s.s_store_name,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq, t.t_hour, s.s_store_id, s.s_store_name
),
web_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amount,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq, t.t_hour
)
SELECT
    ca.d_date,
    ca.d_year,
    ca.d_month_seq,
    ca.t_hour,
    ca.s_store_id,
    ca.s_store_name,
    ca.catalog_return_cnt,
    wa.web_return_cnt,
    ca.catalog_net_loss,
    wa.web_net_loss,
    ca.catalog_return_amount,
    wa.web_return_amount,
    ca.avg_catalog_return_qty,
    wa.avg_web_return_qty,
    CASE
        WHEN (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) > 0 THEN 'POSITIVE'
        WHEN (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) = 0 THEN 'ZERO'
        ELSE 'NEGATIVE'
    END AS total_loss_category,
    (ca.catalog_net_loss / NULLIF(COALESCE(wa.web_net_loss, 0), 0)) AS loss_ratio
FROM catalog_agg ca
LEFT JOIN web_agg wa
    ON ca.d_date = wa.d_date
    AND ca.t_hour = wa.t_hour
WHERE (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) <> 0
ORDER BY ca.d_date DESC, ca.t_hour
