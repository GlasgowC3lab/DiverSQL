WITH sales_agg AS (
    SELECT
        'sales' AS source_type,
        w.w_warehouse_id AS location_id,
        SUM(cs.cs_net_paid) AS total_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS net_profit_sign
    FROM tpcds.catalog_sales cs
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM tpcds.inventory inv
          WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_quantity_on_hand > 0
            AND inv.inv_date_sk = 2451088
      )
    GROUP BY w.w_warehouse_id
    HAVING SUM(cs.cs_net_paid) > 10000
),
returns_agg AS (
    SELECT
        'return' AS source_type,
        s.s_store_id AS location_id,
        SUM(sr.sr_return_amt) AS total_amount,
        SUM(sr.sr_return_quantity) AS total_quantity,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS net_profit_sign
    FROM tpcds.store_returns sr
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer_address ca2
          WHERE ca2.ca_address_sk = sr.sr_addr_sk
            AND ca2.ca_state = 'CA'
      )
    GROUP BY s.s_store_id
    HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
LIMIT 100
