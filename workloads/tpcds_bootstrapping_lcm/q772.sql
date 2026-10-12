WITH aggregated AS (
    SELECT
        d.d_year,
        sm.sm_type,
        s.s_country,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(cr.cr_return_quantity) AS catalog_quantity,
        SUM(wr.wr_return_quantity) AS web_quantity,
        AVG(cr.cr_return_ship_cost) AS avg_catalog_ship_cost,
        AVG(wr.wr_return_ship_cost) AS avg_web_ship_cost
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2020
    GROUP BY d.d_year, sm.sm_type, s.s_country
    HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
)
SELECT
    a.d_year,
    a.sm_type,
    a.s_country,
    a.catalog_return_orders,
    a.web_return_orders,
    a.catalog_net_loss,
    a.web_net_loss,
    a.catalog_return_amount,
    a.web_return_amount,
    a.catalog_quantity,
    a.web_quantity,
    a.avg_catalog_ship_cost,
    a.avg_web_ship_cost,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY (a.catalog_net_loss + a.web_net_loss) DESC) AS rank_by_total_net_loss
FROM aggregated a
ORDER BY a.d_year, rank_by_total_net_loss
LIMIT 100
