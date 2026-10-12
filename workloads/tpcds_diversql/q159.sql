WITH
    high_sales AS (
        SELECT
            i.i_class AS i_class,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(*) AS cnt
        FROM catalog_sales cs
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_ext_sales_price > 2000
          AND cd.cd_purchase_estimate >= 6000
          AND i.i_current_price > 50
        GROUP BY i.i_class
    ),
    low_sales AS (
        SELECT
            i.i_class AS i_class,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(*) AS cnt
        FROM catalog_sales cs
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_ext_sales_price <= 2000
          AND cd.cd_purchase_estimate < 6000
          AND i.i_current_price <= 50
        GROUP BY i.i_class
    ),
    high_avg AS (
        SELECT
            i_class,
            total_profit / NULLIF(cnt, 0) AS avg_profit,
            total_sales
        FROM high_sales
    ),
    low_avg AS (
        SELECT
            i_class,
            total_profit / NULLIF(cnt, 0) AS avg_profit,
            total_sales
        FROM low_sales
    )
SELECT *
FROM high_avg
EXCEPT
SELECT *
FROM low_avg
ORDER BY avg_profit DESC
