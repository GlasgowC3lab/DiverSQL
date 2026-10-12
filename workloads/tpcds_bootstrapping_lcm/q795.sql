WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        s.s_state,
        w.w_city,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
        AVG(wr.wr_return_amt) AS avg_web_return_amount
    FROM date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state = w.w_state
    GROUP BY d.d_year, d.d_quarter_seq, s.s_state, w.w_city
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    a.d_year,
    a.d_quarter_seq,
    a.s_state,
    a.w_city,
    a.catalog_return_orders,
    a.web_return_orders,
    a.total_catalog_net_loss,
    a.total_web_net_loss,
    CASE
        WHEN a.total_catalog_net_loss = 0 THEN NULL
        ELSE a.total_web_net_loss / a.total_catalog_net_loss
    END AS web_to_catalog_loss_ratio,
    a.avg_catalog_return_amount,
    a.avg_web_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_catalog_net_loss DESC) AS catalog_loss_rank_by_year
FROM aggregated a
ORDER BY a.d_year, a.d_quarter_seq
LIMIT 200
