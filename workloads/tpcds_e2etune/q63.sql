SELECT
  ws.web_name,
  r.r_reason_desc,
  d.d_quarter_seq,
  COUNT(*) AS returns_cnt,
  SUM(wr.wr_net_loss) AS total_net_loss,
  AVG(wr.wr_net_loss) AS avg_net_loss,
  RANK() OVER (PARTITION BY d.d_quarter_seq ORDER BY AVG(wr.wr_net_loss) DESC) AS rank_by_quarter
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws ON d.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
WHERE d.d_holiday = 'Y'
  AND d.d_weekend = 'Y'
  AND d.d_fy_year = (SELECT MAX(d2.d_fy_year) FROM date_dim d2)
GROUP BY ws.web_name, r.r_reason_desc, d.d_quarter_seq
HAVING COUNT(*) >= 5
ORDER BY total_net_loss DESC
LIMIT 10
