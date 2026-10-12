SELECT
  wp.wp_type,
  r.r_reason_desc,
  COUNT(*) AS return_cnt,
  SUM(sr.sr_refunded_cash) AS total_refunded_cash,
  AVG(sr.sr_return_amt) AS avg_return_amt,
  RANK() OVER (ORDER BY SUM(sr.sr_refunded_cash) DESC) AS cash_rank
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_country IN ('CHILE', 'MEXICO')
  AND wp.wp_creation_date_sk BETWEEN 2450000 AND 2455000
GROUP BY wp.wp_type, r.r_reason_desc
HAVING COUNT(*) > 10
ORDER BY total_refunded_cash DESC
LIMIT 100
