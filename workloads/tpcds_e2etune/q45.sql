WITH sales_by_store_gender AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_state,
           s.s_number_employees,
           cd.cd_gender AS gender,
           COUNT(*) AS sales_txn_cnt,
           SUM(ss.ss_net_profit) AS total_sales_profit,
           SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_number_employees, cd.cd_gender
),
returns_by_gender AS (
    SELECT cd.cd_gender AS gender,
           COUNT(*) AS return_txn_cnt,
           SUM(wr.wr_net_loss) AS total_return_loss,
           SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT sbsg.s_store_name,
       sbsg.s_state,
       sbsg.gender,
       sbsg.sales_txn_cnt,
       sbsg.total_sales_profit,
       rbg.return_txn_cnt,
       rbg.total_return_loss,
       (sbsg.total_sales_profit - COALESCE(rbg.total_return_loss, 0)) AS net_profit,
       (sbsg.total_sales_profit - COALESCE(rbg.total_return_loss, 0)) / NULLIF(sbsg.s_number_employees, 0) AS profit_per_employee,
       RANK() OVER (
           PARTITION BY sbsg.gender
           ORDER BY (sbsg.total_sales_profit - COALESCE(rbg.total_return_loss, 0)) / NULLIF(sbsg.s_number_employees, 0) DESC
       ) AS gender_store_rank
FROM sales_by_store_gender sbsg
LEFT JOIN returns_by_gender rbg ON sbsg.gender = rbg.gender
WHERE sbsg.sales_txn_cnt >= 500
ORDER BY net_profit DESC
LIMIT 100
