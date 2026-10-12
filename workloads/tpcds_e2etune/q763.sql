WITH agg AS (
    SELECT cp.cp_department,
           d.d_year,
           d.d_month_seq,
           SUM(wr.wr_net_loss) AS total_net_loss,
           AVG(wr.wr_return_amt) AS avg_return_amount,
           COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2003
      AND cd_ref.cd_education_status = 'College'
      AND cd_ret.cd_gender = 'M'
      AND cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number IN (1, 2, 3)
    GROUP BY cp.cp_department, d.d_year, d.d_month_seq
)
SELECT agg.cp_department,
       agg.d_year,
       agg.d_month_seq,
       agg.total_net_loss,
       agg.avg_return_amount,
       agg.distinct_orders,
       RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_net_loss DESC) AS dept_loss_rank
FROM agg
ORDER BY agg.d_year, agg.total_net_loss DESC
LIMIT 100
