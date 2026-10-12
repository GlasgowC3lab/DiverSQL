WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        SUM(cr.cr_return_quantity) + SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed_on_date
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.i_item_id,
    a.i_product_name,
    a.catalog_net_loss,
    a.web_net_loss,
    a.total_return_quantity,
    a.stores_closed_on_date,
    CASE
        WHEN a.catalog_net_loss > a.web_net_loss THEN 'Catalog higher'
        WHEN a.catalog_net_loss < a.web_net_loss THEN 'Web higher'
        ELSE 'Equal'
    END AS loss_comparison,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY (a.catalog_net_loss + a.web_net_loss) DESC) AS loss_rank
FROM agg a
ORDER BY a.d_year, a.d_month_seq, loss_rank
LIMIT 100
