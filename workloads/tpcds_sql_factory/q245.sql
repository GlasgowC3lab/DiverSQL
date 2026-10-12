WITH cs_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_bill_cdemo_sk AS cd_demo_sk,
           SUM(cs.cs_net_paid_inc_tax) AS cs_sales,
           SUM(cs.cs_quantity) AS cs_quantity,
           COUNT(DISTINCT cs.cs_order_number) AS cs_orders
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_bill_cdemo_sk
),
ss_sales AS (
    SELECT ss.ss_item_sk,
           ss.ss_cdemo_sk AS cd_demo_sk,
           SUM(ss.ss_net_paid_inc_tax) AS ss_sales,
           SUM(ss.ss_quantity) AS ss_quantity,
           COUNT(DISTINCT ss.ss_ticket_number) AS ss_orders
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_cdemo_sk
),
returns AS (
    SELECT wr.wr_item_sk,
           wr.wr_refunded_cdemo_sk AS cd_demo_sk,
           SUM(wr.wr_return_amt_inc_tax) AS return_sales,
           SUM(wr.wr_return_quantity) AS return_quantity,
           COUNT(DISTINCT wr.wr_order_number) AS return_orders
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_refunded_cdemo_sk
),
sales_combined AS (
    SELECT
        COALESCE(cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
        COALESCE(cs.cd_demo_sk, ss.cd_demo_sk, r.cd_demo_sk) AS cd_demo_sk,
        COALESCE(cs.cs_sales, 0) + COALESCE(ss.ss_sales, 0) AS total_sales,
        COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0) AS total_quantity,
        COALESCE(cs.cs_orders, 0) + COALESCE(ss.ss_orders, 0) AS total_transactions,
        COALESCE(r.return_sales, 0) AS total_return_sales,
        COALESCE(r.return_quantity, 0) AS total_return_quantity,
        COALESCE(r.return_orders, 0) AS total_return_orders
    FROM cs_sales cs
    FULL OUTER JOIN ss_sales ss
        ON cs.cs_item_sk = ss.ss_item_sk
        AND cs.cd_demo_sk = ss.cd_demo_sk
    LEFT JOIN returns r
        ON COALESCE(cs.cs_item_sk, ss.ss_item_sk) = r.wr_item_sk
        AND COALESCE(cs.cd_demo_sk, ss.cd_demo_sk) = r.cd_demo_sk
),
final AS (
    SELECT
        sc.item_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        sc.total_sales,
        sc.total_return_sales,
        CASE 
            WHEN sc.total_sales = 0 THEN 0
            ELSE sc.total_return_sales / sc.total_sales
        END AS return_ratio,
        CASE 
            WHEN sc.total_sales = 0 THEN NULL
            ELSE sc.total_sales - sc.total_return_sales
        END AS net_sales_after_return
    FROM sales_combined sc
    LEFT JOIN customer_demographics cd ON sc.cd_demo_sk = cd.cd_demo_sk
    WHERE sc.total_sales > 0
)
SELECT
    item_sk,
    cd_gender,
    cd_marital_status,
    total_sales,
    total_return_sales,
    return_ratio,
    net_sales_after_return,
    CASE 
        WHEN return_ratio > 0.5 THEN 'Very High'
        WHEN return_ratio > 0.3 THEN 'High'
        WHEN return_ratio > 0.1 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY return_ratio DESC) AS gender_return_rank,
    RANK() OVER (ORDER BY net_sales_after_return DESC) AS net_sales_rank
FROM final
ORDER BY net_sales_rank
LIMIT 20
