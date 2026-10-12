WITH intersect_keys AS (
    SELECT cr_order_number AS key
    FROM catalog_returns
    WHERE cr_reversed_charge > 1000
    INTERSECT
    SELECT sr_ticket_number
    FROM store_returns
    WHERE sr_return_quantity > 1
),
joined_data AS (
    SELECT
        d.d_year,
        w.w_city,
        t.t_hour,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_order_number,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                           AND sr.sr_return_time_sk = t.t_time_sk
    WHERE d.d_year = 2002
      AND w.w_city = 'Salem'
      AND t.t_hour = 14
      AND cr.cr_reversed_charge > 1000
      AND sr.sr_return_quantity > 1
      AND cr.cr_order_number IN (SELECT key FROM intersect_keys)
)
SELECT
    d_year,
    w_city,
    t_hour,
    COUNT(*) AS cnt_returns,
    SUM(cr_return_amount) AS sum_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    SUM(sr_return_amt) AS sum_store_return_amt,
    MAX(cr_net_loss) AS max_net_loss,
    MIN(sr_net_loss) AS min_store_net_loss
FROM joined_data
GROUP BY ROLLUP (d_year, w_city, t_hour)
ORDER BY d_year DESC, w_city, t_hour
LIMIT 100
