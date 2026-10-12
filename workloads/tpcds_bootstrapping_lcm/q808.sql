WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_creation.d_month_seq AS page_creation_month_seq,
        d_access.d_day_name AS page_access_day_name,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(cr.cr_net_loss) AS catalog_total_net_loss,
        SUM(wr.wr_net_loss) AS web_total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
      AND wp.wp_type = 'Product'
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_creation.d_month_seq,
        d_access.d_day_name
    HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
)
SELECT
    a.s_store_id,
    a.s_city,
    a.s_state,
    a.d_year,
    a.d_month_seq,
    a.catalog_return_orders,
    a.web_return_orders,
    a.catalog_total_net_loss,
    a.web_total_net_loss,
    (a.catalog_total_net_loss + a.web_total_net_loss) AS combined_total_net_loss,
    a.avg_catalog_return_qty,
    a.avg_web_return_qty,
    CASE
        WHEN a.page_creation_month_seq < a.d_month_seq THEN 'Created_before_return'
        ELSE 'Created_after_return'
    END AS page_creation_timing,
    a.page_access_day_name,
    ROW_NUMBER() OVER (
        PARTITION BY a.s_state
        ORDER BY (a.catalog_total_net_loss + a.web_total_net_loss) DESC
    ) AS state_rank
FROM agg a
ORDER BY combined_total_net_loss DESC
LIMIT 100
