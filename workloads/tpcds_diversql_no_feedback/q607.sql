WITH sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
)
SELECT
    r.r_reason_desc,
    CONCAT('Reason: ', r.r_reason_desc) AS reason_label,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COUNT(DISTINCT regexp_extract(i.i_item_desc, '([A-Z]{3})', 1)) AS distinct_codes,
    SUM(CASE WHEN regexp_like(i.i_item_desc, '^.*[0-9]{2}.*$') THEN 1 ELSE 0 END) AS items_with_two_digits,
    SUM(CASE WHEN ws.ws_quantity > 5 THEN 1 ELSE 0 END) AS high_quantity_sales,
    MAX(CASE WHEN regexp_like(wp.wp_url, '^https?://.*') THEN ws.ws_net_paid ELSE NULL END) AS max_paid_for_http_urls
FROM sampled_returns wr
JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    regexp_like(r.r_reason_desc, '(?i)damaged')
    AND wp.wp_url LIKE '%.com%'
    AND substring(i.i_item_desc, 1, 5) = 'Item '
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 20
