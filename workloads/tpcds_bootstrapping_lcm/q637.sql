WITH daily_agg AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        s.s_state,
        s.s_city,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        AVG(s.s_tax_percentage) AS avg_tax_percentage
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                         AND wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND r.r_reason_desc LIKE '%defect%'
      AND s.s_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc, s.s_state, s.s_city
    HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 1000
)
SELECT 
    d_year,
    d_month_seq,
    r_reason_desc,
    s_state,
    s_city,
    catalog_order_cnt,
    catalog_net_loss,
    web_order_cnt,
    web_net_loss,
    catalog_return_qty,
    web_return_qty,
    (catalog_return_qty + web_return_qty) AS total_return_qty,
    avg_tax_percentage,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (catalog_net_loss + web_net_loss) DESC) AS loss_rank
FROM daily_agg
ORDER BY d_year DESC, total_return_qty DESC
LIMIT 100
