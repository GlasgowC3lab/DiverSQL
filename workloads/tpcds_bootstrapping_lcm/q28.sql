WITH aggregated_returns AS (
    SELECT
        dd.d_date,
        dd.d_year,
        sm.sm_ship_mode_sk,
        sm.sm_type,
        sm.sm_carrier,
        s.s_store_name,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(cr.cr_return_quantity + wr.wr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
        AVG(wr.wr_return_amt) AS avg_web_return_amount
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2000 AND 2002
      AND sm.sm_type IN ('AIR', 'GROUND')
    GROUP BY
        dd.d_date,
        dd.d_year,
        sm.sm_ship_mode_sk,
        sm.sm_type,
        sm.sm_carrier,
        s.s_store_name
)
SELECT
    ar.d_date,
    ar.d_year,
    ar.sm_type,
    ar.sm_carrier,
    ar.s_store_name,
    ar.catalog_return_orders,
    ar.web_return_orders,
    ar.total_catalog_net_loss,
    ar.total_web_net_loss,
    ar.total_return_quantity,
    ar.avg_catalog_return_amount,
    ar.avg_web_return_amount,
    CASE WHEN ar.total_web_net_loss = 0 THEN NULL
         ELSE ar.total_catalog_net_loss / ar.total_web_net_loss END AS loss_ratio
FROM aggregated_returns ar
WHERE ar.total_catalog_net_loss + ar.total_web_net_loss > 5000
ORDER BY ar.total_catalog_net_loss DESC
LIMIT 50
