WITH
    store_losses AS (
        SELECT
            'STORE' AS source_type,
            s.s_store_id AS entity_id,
            d.d_year AS year,
            SUM(sr.sr_net_loss) AS total_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        WHERE d.d_year = 2001
          AND s.s_tax_percentage > 0.05
        GROUP BY s.s_store_id, d.d_year
    ),
    warehouse_losses AS (
        SELECT
            'WAREHOUSE' AS source_type,
            w.w_warehouse_id AS entity_id,
            d.d_year AS year,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2001
          AND w.w_state = 'CA'
          AND NOT EXISTS (
                SELECT 1
                FROM inventory i
                WHERE i.inv_date_sk = d.d_date_sk
                  AND i.inv_warehouse_sk = w.w_warehouse_sk
          )
        GROUP BY w.w_warehouse_id, d.d_year
    ),
    combined AS (
        SELECT * FROM store_losses
        UNION ALL
        SELECT * FROM warehouse_losses
    )
SELECT
    source_type,
    entity_id,
    year,
    total_net_loss
FROM combined
ORDER BY source_type, total_net_loss DESC
LIMIT 100
