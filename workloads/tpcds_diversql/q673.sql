SELECT web_mkt_class,
       COUNT(*) AS site_count,
       AVG(web_gmt_offset) AS avg_gmt_offset
FROM tpcds.web_site
WHERE web_mkt_class = 'Wide'
  AND web_close_date_sk = 2441469
GROUP BY web_mkt_class
