WITH hourly_stats AS (
    SELECT
        t.t_hour,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count > 2
    GROUP BY t.t_hour
)
SELECT
    h.t_hour,
    h.return_cnt,
    h.avg_return_amount,
    h.avg_return_tax,
    CASE
        WHEN h.avg_return_tax > 10 THEN 'HIGH_TAX'
        ELSE 'NORMAL_TAX'
    END AS tax_category,
    DENSE_RANK() OVER (ORDER BY h.avg_return_amount DESC) AS amount_rank
FROM hourly_stats h
ORDER BY h.t_hour
