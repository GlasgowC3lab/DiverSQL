WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        d.d_year,
        c.c_customer_id,
        cd.cd_credit_rating,
        ca.ca_state,
        w.w_warehouse_id,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        sr.sr_return_tax,
        s.s_store_id
    FROM store_returns sr
    FULL OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
           AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'TX'
      AND cd.cd_credit_rating = 'High Risk'
      AND sr.sr_return_tax > 10.00
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
            AND cs2.cs_sold_date_sk = d.d_date_sk
      )
),
agg AS (
    SELECT
        d_year,
        ca_state,
        cd_credit_rating,
        SUM(cs_net_paid) AS total_sales,
        SUM(sr_return_amt) AS total_returns,
        COUNT(*) AS txn_count,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM base
    GROUP BY ROLLUP (d_year, ca_state, cd_credit_rating)
)
SELECT *
FROM (
    SELECT
        d_year,
        ca_state,
        cd_credit_rating,
        total_sales,
        total_returns,
        txn_count,
        avg_inventory,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rn
    FROM agg
) t
WHERE rn <= 5
UNION
SELECT *
FROM (
    SELECT
        d_year,
        ca_state,
        cd_credit_rating,
        total_sales,
        total_returns,
        txn_count,
        avg_inventory,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_returns DESC) AS rn
    FROM agg
) t2
WHERE rn <= 5
ORDER BY d_year, total_sales DESC
LIMIT 100
