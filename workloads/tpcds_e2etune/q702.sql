WITH page_returns AS (
   SELECT
       wr.wr_web_page_sk AS page_sk,
       COUNT(*) AS return_cnt,
       SUM(wr.wr_return_amt) AS total_return_amt,
       AVG(wr.wr_return_amt) AS avg_return_amt,
       SUM(wr.wr_net_loss) AS total_net_loss,
       SUM(wr.wr_return_quantity) AS total_qty
   FROM web_returns wr
   WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2451200
   GROUP BY wr.wr_web_page_sk
   HAVING SUM(wr.wr_return_amt) > 5000
)
SELECT
   cp.cp_department,
   cp.cp_type,
   date_format(date_add('day', cp.cp_start_date_sk, DATE '1900-01-01'), '%Y-%m') AS start_month,
   pr.return_cnt,
   pr.total_return_amt,
   pr.avg_return_amt,
   pr.total_net_loss,
   pr.total_qty,
   RANK() OVER (PARTITION BY cp.cp_department ORDER BY pr.total_return_amt DESC) AS dept_return_rank
FROM catalog_page cp
JOIN page_returns pr
   ON cp.cp_catalog_page_sk = pr.page_sk
WHERE cp.cp_type IN ('monthly', 'quarterly')
  AND cp.cp_department IS NOT NULL
ORDER BY pr.total_return_amt DESC
LIMIT 50
