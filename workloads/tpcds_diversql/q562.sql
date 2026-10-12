WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_ret
    FROM catalog_returns
    WHERE cr_return_quantity > 0
)
SELECT
    ws.web_site_id,
    CONCAT(ws.web_name, ' - ', ws.web_city) AS site_full_name,
    CASE
        WHEN regexp_like(ws.web_mkt_desc, '(?i)issues') THEN 'Issue'
        ELSE 'Other'
    END AS market_category,
    regexp_extract(ws.web_mkt_desc, '^([^,]+)', 1) AS first_phrase,
    COUNT(cr.cr_order_number) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE ws.web_city LIKE 'A%'
  AND cr.cr_return_amount > (SELECT avg_ret FROM avg_return)
  AND regexp_like(ws.web_mkt_desc, '^Concerned|royal')
GROUP BY
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_mkt_desc
ORDER BY total_return_amount DESC
OFFSET 0 LIMIT 100
