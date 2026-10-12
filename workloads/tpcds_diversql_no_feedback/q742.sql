SELECT
    w_warehouse_id,
    cd_gender,
    cd_marital_status,
    total_sales,
    avg_profit
FROM (
    SELECT
        w.w_warehouse_id AS w_warehouse_id,
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cd.cd_purchase_estimate >= 3000
      AND w.w_state = 'CA'
    GROUP BY CUBE (w.w_warehouse_id, cd.cd_gender, cd.cd_marital_status)

    UNION ALL

    SELECT
        w.w_warehouse_id AS w_warehouse_id,
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cd.cd_purchase_estimate >= 3000
      AND w.w_state = 'CA'
    GROUP BY CUBE (w.w_warehouse_id, cd.cd_gender, cd.cd_marital_status)
) AS combined
ORDER BY total_sales DESC
LIMIT 100
