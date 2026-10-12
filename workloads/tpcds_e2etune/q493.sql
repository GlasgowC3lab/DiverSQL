WITH monthly_store_sales AS (
    SELECT
        d.d_year,
        d.d_moy,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        COUNT(*) AS store_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_moy, ss.ss_store_sk
),
monthly_catalog_sales AS (
    SELECT
        d.d_year,
        d.d_moy,
        cs.cs_warehouse_sk,
        sm.sm_ship_mode_id,
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        COUNT(*) AS catalog_transactions
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cs.cs_ext_discount_amt > 5.00
      AND cd.cd_credit_rating = 'A'
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, d.d_moy, cs.cs_warehouse_sk, sm.sm_ship_mode_id, cd.cd_gender, cd.cd_credit_rating
)
SELECT
    ms.d_year,
    ms.d_moy,
    ms.ss_store_sk,
    mc.cs_warehouse_sk,
    mc.sm_ship_mode_id,
    mc.cd_gender,
    ms.store_net_profit,
    mc.catalog_net_profit,
    (ms.store_net_profit + mc.catalog_net_profit) AS total_net_profit,
    (ms.store_sales + mc.catalog_sales) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY ms.d_year, ms.d_moy ORDER BY (ms.store_net_profit + mc.catalog_net_profit) DESC) AS profit_rank
FROM monthly_store_sales ms
JOIN monthly_catalog_sales mc
  ON ms.d_year = mc.d_year
 AND ms.d_moy = mc.d_moy
WHERE (ms.store_net_profit + mc.catalog_net_profit) > 10000
ORDER BY ms.d_year, ms.d_moy, profit_rank
LIMIT 50
