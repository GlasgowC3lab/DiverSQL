WITH catalog_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(cr.cr_net_loss) AS catalog_total_net_loss,
        COUNT(*) AS catalog_return_count,
        SUM(cr.cr_return_amount) AS catalog_total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_warehouse_sk
),
web_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_net_loss) AS web_total_net_loss,
        COUNT(*) AS web_return_count,
        SUM(wr.wr_return_amt) AS web_total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
store_info AS (
    SELECT
        s.s_closed_date_sk AS date_sk,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM store s
    WHERE s.s_closed_date_sk IS NOT NULL
)
SELECT
    d.d_year,
    d.d_moy AS month,
    si.s_store_name,
    si.s_city,
    si.s_state,
    w.w_warehouse_name,
    w.w_state AS warehouse_state,
    ca.catalog_return_count,
    ca.catalog_total_net_loss,
    ca.catalog_total_return_amount,
    wa.web_return_count,
    wa.web_total_net_loss,
    wa.web_total_return_amount,
    (ca.catalog_total_net_loss - COALESCE(wa.web_total_net_loss, 0)) AS net_loss_diff,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ca.catalog_total_net_loss DESC) AS catalog_loss_rank_by_year
FROM
    date_dim d
    LEFT JOIN catalog_agg ca ON ca.date_sk = d.d_date_sk
    LEFT JOIN web_agg wa ON wa.date_sk = d.d_date_sk
    LEFT JOIN store_info si ON si.date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = ca.warehouse_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
    AND ca.catalog_total_net_loss IS NOT NULL
ORDER BY
    d.d_year,
    d.d_moy,
    net_loss_diff DESC
LIMIT 200
