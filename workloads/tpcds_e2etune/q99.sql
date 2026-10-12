WITH returns_agg AS (
   SELECT
       cp.cp_type,
       d_ret.d_year,
       d_ret.d_moy,
       SUM(cr.cr_net_loss) AS total_net_loss,
       SUM(cr.cr_return_amount) AS total_return_amount,
       AVG(cr.cr_return_quantity) AS avg_return_qty,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   WHERE cp.cp_type IS NOT NULL
     AND d_ret.d_year BETWEEN 2015 AND 2022
   GROUP BY cp.cp_type, d_ret.d_year, d_ret.d_moy
),
web_page_agg AS (
   SELECT
       d_wp.d_year,
       d_wp.d_moy,
       COUNT(*) AS web_page_count
   FROM web_page wp
   JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
   WHERE d_wp.d_year BETWEEN 2015 AND 2022
   GROUP BY d_wp.d_year, d_wp.d_moy
)
SELECT
    r.cp_type,
    r.d_year,
    r.d_moy,
    r.total_net_loss,
    r.total_return_amount,
    r.avg_return_qty,
    COALESCE(w.web_page_count, 0) AS web_page_count,
    r.total_net_loss / NULLIF(COALESCE(w.web_page_count, 0), 0) AS net_loss_per_page,
    RANK() OVER (PARTITION BY r.d_year, r.d_moy ORDER BY r.total_net_loss DESC) AS loss_rank_by_month
FROM returns_agg r
LEFT JOIN web_page_agg w
    ON r.d_year = w.d_year AND r.d_moy = w.d_moy
ORDER BY r.d_year DESC, r.d_moy DESC, loss_rank_by_month
LIMIT 200
