WITH recent_dates AS (
    SELECT d_date_sk
    FROM tpcds.date_dim
    WHERE d_year = 2020
),
store_agg AS (
    SELECT
        s.s_store_sk AS entity_id,
        s.s_store_name AS entity_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        'Store' AS entity_type
    FROM tpcds.store_returns sr
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN recent_dates rd
        ON sr.sr_returned_date_sk = rd.d_date_sk
    WHERE s.s_store_sk IN (
        SELECT DISTINCT sr2.sr_store_sk
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)
    )
    GROUP BY s.s_store_sk, s.s_store_name
),
warehouse_agg AS (
    SELECT
        w.w_warehouse_sk AS entity_id,
        w.w_warehouse_name AS entity_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        'Warehouse' AS entity_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN recent_dates rd
        ON cr.cr_returned_date_sk = rd.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
          AND cr2.cr_net_loss > 0
    )
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM warehouse_agg
ORDER BY total_net_loss DESC
LIMIT 100
