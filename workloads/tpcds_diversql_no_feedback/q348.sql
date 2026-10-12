WITH store_ret AS (
   SELECT
       d.d_date AS return_date,
       'Store' AS source,
       s.s_store_name AS entity_name,
       CAST(SUM(sr.sr_return_amt) AS decimal(15,2)) AS total_return_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
     AND s.s_state = 'CA'
   GROUP BY d.d_date, s.s_store_name
),
web_ret AS (
   SELECT
       d.d_date AS return_date,
       'Web' AS source,
       ws.web_name AS entity_name,
       CAST(SUM(wr.wr_return_amt) AS decimal(15,2)) AS total_return_amount
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_sales wsale ON wr.wr_order_number = wsale.ws_order_number
                      AND wr.wr_item_sk = wsale.ws_item_sk
   JOIN web_site ws ON wsale.ws_web_site_sk = ws.web_site_sk
   WHERE d.d_year = 2001
     AND ws.web_state = 'CA'
   GROUP BY d.d_date, ws.web_name
)
SELECT return_date, source, entity_name, total_return_amount
FROM store_ret
UNION
SELECT return_date, source, entity_name, total_return_amount
FROM web_ret
ORDER BY return_date DESC, source, total_return_amount DESC
LIMIT 100
