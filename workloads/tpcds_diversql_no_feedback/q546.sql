WITH
    catalog_agg AS (
        SELECT
            cr_warehouse_sk,
            cr_returned_date_sk,
            cr_call_center_sk,
            SUM(cr_net_loss) AS catalog_net_loss,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns
        GROUP BY cr_warehouse_sk, cr_returned_date_sk, cr_call_center_sk
    ),
    inventory_sampled AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY final.d_date) AS row_num,
    final.d_date,
    final.d_year,
    final.warehouse_name,
    final.call_center_name,
    final.catalog_net_loss,
    final.catalog_return_cnt,
    final.total_store_net_loss,
    final.store_return_cnt,
    final.inv_quantity_on_hand,
    final.weighted_loss,
    final.grp,
    final.dummy_date
FROM (
    SELECT
        d.d_date,
        d.d_year,
        w.w_warehouse_name AS warehouse_name,
        cc.cc_name AS call_center_name,
        ca.catalog_net_loss,
        ca.catalog_return_cnt,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(sr.sr_ticket_number) AS store_return_cnt,
        inv.inv_quantity_on_hand,
        (inv.inv_quantity_on_hand * ca.catalog_net_loss) AS weighted_loss,
        ds.grp,
        dd.d_date AS dummy_date
    FROM catalog_agg ca
    JOIN date_dim d
        ON ca.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON ca.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON ca.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_sampled inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) ds
    CROSS JOIN (SELECT d_date FROM date_dim WHERE d_year = 2000) dd
    GROUP BY
        d.d_date,
        d.d_year,
        w.w_warehouse_name,
        cc.cc_name,
        ca.catalog_net_loss,
        ca.catalog_return_cnt,
        inv.inv_quantity_on_hand,
        ds.grp,
        dd.d_date
) final
ORDER BY final.d_date
LIMIT 100
