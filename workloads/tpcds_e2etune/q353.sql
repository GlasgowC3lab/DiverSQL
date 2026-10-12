WITH sales_agg AS (
  SELECT
    cp.cp_department AS department,
    cp.cp_type AS catalog_type,
    ws.web_state AS website_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN catalog_page cp
    ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
  JOIN web_site ws
    ON ss.ss_sold_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
  WHERE cp.cp_type = 'monthly'
    AND ws.web_country = 'United States'
    AND ss.ss_net_paid > 0
  GROUP BY cp.cp_department, cp.cp_type, ws.web_state
  HAVING SUM(ss.ss_net_paid) > 100000
)
SELECT
  department,
  catalog_type,
  website_state,
  num_tickets,
  total_net_paid,
  total_net_profit,
  avg_discount,
  total_quantity,
  RANK() OVER (PARTITION BY website_state ORDER BY total_net_paid DESC) AS dept_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
