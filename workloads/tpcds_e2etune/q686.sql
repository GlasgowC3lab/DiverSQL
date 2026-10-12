WITH dept_monthly AS (
    SELECT
        cp.cp_department AS department,
        d_sales.d_year AS year,
        d_sales.d_moy AS month,
        SUM(ss.ss_net_paid) AS total_sales_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_quantity
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    WHERE d_sales.d_year = 2001
      AND cp.cp_catalog_page_number IN (1, 2, 3)
    GROUP BY cp.cp_department, d_sales.d_year, d_sales.d_moy
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    department,
    year,
    month,
    total_sales_amount,
    total_return_amount,
    total_net_profit - total_net_loss AS net_profit_after_returns,
    CASE WHEN total_quantity = 0 THEN 0
         ELSE total_return_quantity / total_quantity END AS return_rate,
    RANK() OVER (PARTITION BY year ORDER BY (total_net_profit - total_net_loss) DESC) AS profit_rank
FROM dept_monthly
ORDER BY net_profit_after_returns DESC
LIMIT 100
