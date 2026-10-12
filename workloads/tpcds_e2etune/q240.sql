WITH hourly_returns AS (
    SELECT
        td.t_hour,
        td.t_shift,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        AVG(cr.cr_net_loss) AS avg_catalog_net_loss,
        AVG(sr.sr_net_loss) AS avg_store_net_loss,
        COUNT(*) FILTER (WHERE cr.cr_fee > 50) AS high_fee_catalog_returns,
        COUNT(*) FILTER (WHERE sr.sr_fee > 50) AS high_fee_store_returns
    FROM
        catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    WHERE
        cr.cr_return_ship_cost > 0
        AND sr.sr_return_quantity >= 2
        AND td.t_hour BETWEEN 8 AND 20
    GROUP BY
        td.t_hour,
        td.t_shift
    HAVING
        SUM(cr.cr_return_amount) > 1000
)
SELECT
    hr.t_hour,
    hr.t_shift,
    hr.catalog_return_orders,
    hr.total_catalog_return_amount,
    hr.total_store_return_amount,
    hr.avg_catalog_net_loss,
    hr.avg_store_net_loss,
    hr.high_fee_catalog_returns,
    hr.high_fee_store_returns,
    RANK() OVER (PARTITION BY hr.t_shift ORDER BY hr.total_store_return_amount DESC) AS shift_store_return_rank
FROM
    hourly_returns hr
ORDER BY
    hr.total_store_return_amount DESC
LIMIT 50
