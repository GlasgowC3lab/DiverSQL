WITH dept_agg AS (
    SELECT cp.cp_department AS department,
           COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
           SUM(wr.wr_net_loss) AS total_net_loss,
           AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM catalog_page cp
    JOIN web_returns wr
      ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND cp.cp_catalog_number IN (1, 2, 3)
      AND wr.wr_return_amt > 0
    GROUP BY cp.cp_department
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT department,
       num_pages,
       total_net_loss,
       avg_return_qty,
       RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM dept_agg
ORDER BY total_net_loss DESC
LIMIT 100
