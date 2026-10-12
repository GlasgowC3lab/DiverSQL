WITH returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        COUNT(*) AS return_cnt,
        regexp_extract(s.s_store_name, '(\\d+)', 1) AS store_number
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_city LIKE 'A%'
      AND regexp_like(s.s_store_name, '\\d')
    GROUP BY sr.sr_returned_date_sk, s.s_store_name
),
sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_quantity) AS sales_qty,
        regexp_extract(w.web_name, '(\\d+)', 1) AS web_number
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(w.web_name, '^.*Corp.*$')
    GROUP BY ws.ws_sold_date_sk, w.web_name
)

SELECT *
FROM (
    SELECT date_sk, return_cnt, store_number
    FROM returns_agg
) 
EXCEPT
SELECT date_sk, sales_qty, web_number
FROM sales_agg
ORDER BY return_cnt DESC
LIMIT 100
