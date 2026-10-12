SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_return.d_year,
    d_return.d_quarter_name,
    wp.wp_type,
    d_creation.d_current_month AS page_creation_month,
    d_access.d_day_name AS page_access_day,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amount + cr.cr_return_tax) AS catalog_total_return,
    SUM(wr.wr_return_amt + wr.wr_return_tax) AS web_total_return,
    ROUND(
        CASE 
            WHEN SUM(wr.wr_net_loss) = 0 THEN NULL
            ELSE (SUM(cr.cr_net_loss) / SUM(wr.wr_net_loss))
        END, 2) AS loss_ratio,
    CASE 
        WHEN SUM(cr.cr_net_loss) > SUM(wr.wr_net_loss) THEN 'Catalog higher'
        ELSE 'Web higher'
    END AS higher_loss_source,
    RANK() OVER (
        PARTITION BY d_return.d_year
        ORDER BY (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) DESC
    ) AS loss_rank
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'TX'
  AND wp.wp_type IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_return.d_year,
    d_return.d_quarter_name,
    wp.wp_type,
    d_creation.d_current_month,
    d_access.d_day_name
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY d_return.d_year, loss_rank
LIMIT 100
