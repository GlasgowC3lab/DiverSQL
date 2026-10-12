SELECT wp.wp_url,
       wp.wp_type,
       SUM(wr.wr_return_amt) AS total_return_amount,
       COUNT(*) AS return_cnt
FROM tpcds.web_returns wr
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_link_count >= 12
  AND wr.wr_returned_date_sk = 2451171
GROUP BY wp.wp_url, wp.wp_type
ORDER BY total_return_amount DESC
LIMIT 10
