WITH catalog_agg AS (
    SELECT
        i.i_category,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_profit,
        AVG(cs.cs_ext_discount_amt) AS catalog_avg_discount,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_warehouse_sk IN (14, 2, 7)
      AND cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_promo_sk IN (1096, 1170)
    GROUP BY i.i_category, sm.sm_ship_mode_id
),
store_agg AS (
    SELECT
        i.i_category,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_profit,
        AVG(ss.ss_ext_discount_amt) AS store_avg_discount,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid_inc_tax > 1000
    GROUP BY i.i_category
)
SELECT
    ca.i_category,
    ca.sm_ship_mode_id,
    ca.catalog_net_paid,
    ca.catalog_profit,
    ca.catalog_avg_discount,
    ca.catalog_txn_cnt,
    sa.store_net_paid,
    sa.store_profit,
    sa.store_avg_discount,
    sa.store_txn_cnt,
    (ca.catalog_net_paid + COALESCE(sa.store_net_paid, 0)) AS total_net_paid,
    (ca.catalog_profit + COALESCE(sa.store_profit, 0)) AS total_profit,
    CASE WHEN (ca.catalog_txn_cnt + COALESCE(sa.store_txn_cnt, 0)) > 0
         THEN (ca.catalog_avg_discount * ca.catalog_txn_cnt + COALESCE(sa.store_avg_discount * sa.store_txn_cnt, 0))
              / (ca.catalog_txn_cnt + COALESCE(sa.store_txn_cnt, 0))
         ELSE NULL END AS overall_avg_discount
FROM catalog_agg ca
LEFT JOIN store_agg sa
    ON ca.i_category = sa.i_category
ORDER BY total_net_paid DESC
LIMIT 100
