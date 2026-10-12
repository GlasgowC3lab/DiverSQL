SELECT
  ws.web_mkt_desc,
  COUNT(*) AS site_count,
  AVG(ws.web_tax_percentage) AS avg_tax_percentage
FROM tpcds.web_site AS ws
WHERE ws.web_mkt_id IN (1, 4)
  AND ws.web_company_id = 2
GROUP BY ws.web_mkt_desc
HAVING COUNT(*) > 1
ORDER BY site_count DESC
LIMIT 10
