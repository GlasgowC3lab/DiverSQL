WITH demographics_sales AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),

demographics_returns AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_fee) AS return_fee,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    ds.cd_gender,
    ds.cd_marital_status,
    ds.sales_amount,
    COALESCE(dr.return_amount, 0) AS return_amount,
    ds.sales_amount - COALESCE(dr.return_amount, 0) AS net_sales,
    ds.profit_amount - COALESCE(dr.return_fee, 0) AS net_profit,
    ds.sales_transactions,
    COALESCE(dr.return_transactions, 0) AS return_transactions,
    ROUND(100.0 * (ds.sales_amount - COALESCE(dr.return_amount, 0)) / SUM(ds.sales_amount - COALESCE(dr.return_amount, 0)) OVER (), 2) AS sales_pct_of_total,
    RANK() OVER (ORDER BY (ds.sales_amount - COALESCE(dr.return_amount, 0)) DESC) AS sales_rank
FROM demographics_sales ds
LEFT JOIN demographics_returns dr ON ds.cd_demo_sk = dr.cd_demo_sk
ORDER BY net_sales DESC
LIMIT 50
