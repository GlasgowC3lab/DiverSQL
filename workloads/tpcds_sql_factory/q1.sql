WITH combined_returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_qty,
        'catalog' AS source
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_qty,
        'store' AS source
    FROM store_returns sr
),
 daily_agg AS (
    SELECT
        d.d_date AS calendar_date,
        d.d_year,
        d.d_current_month,
        SUM(cr.net_loss) AS daily_net_loss,
        SUM(cr.return_amount) AS daily_return_amount,
        SUM(cr.return_qty) AS daily_return_qty,
        COUNT(*) FILTER (WHERE cr.source = 'catalog') AS catalog_return_cnt,
        COUNT(*) FILTER (WHERE cr.source = 'store') AS store_return_cnt
    FROM combined_returns cr
    JOIN date_dim d ON cr.date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_current_month
)
SELECT
    da.calendar_date,
    da.d_year,
    da.d_current_month,
    da.daily_net_loss,
    da.daily_return_amount,
    da.daily_return_qty,
    da.catalog_return_cnt,
    da.store_return_cnt,
    RANK() OVER (ORDER BY da.daily_net_loss DESC) AS net_loss_rank,
    SUM(da.daily_net_loss) OVER (ORDER BY da.calendar_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_loss,
    CASE
        WHEN da.daily_net_loss > 2000 THEN 'Critical'
        WHEN da.daily_net_loss > 500 THEN 'Warning'
        ELSE 'Normal'
    END AS alert_level
FROM daily_agg da
ORDER BY da.calendar_date DESC
LIMIT 100
