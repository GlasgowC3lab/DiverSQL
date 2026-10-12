SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_name,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
    SUM(cr.cr_net_loss) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) = 0 THEN NULL
        ELSE COALESCE(SUM(wr.wr_net_loss), 0) / SUM(cr.cr_net_loss)
    END AS web_to_catalog_loss_ratio,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty
FROM
    date_dim d
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
GROUP BY
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_name
HAVING
    (SUM(cr.cr_net_loss) + COALESCE(SUM(wr.wr_net_loss), 0)) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
