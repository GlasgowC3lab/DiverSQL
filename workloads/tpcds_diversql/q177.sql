WITH
  store_daily AS (
    SELECT d.d_date AS date,
           SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  ),
  web_daily AS (
    SELECT d.d_date AS date,
           SUM(ws.ws_net_paid) AS web_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  ),
  combined_sales AS (
    SELECT COALESCE(s.date, w.date) AS date,
           s.store_net_paid,
           w.web_net_paid
    FROM store_daily s
    FULL OUTER JOIN web_daily w ON s.date = w.date
  ),
  catalog_loss_daily AS (
    SELECT d.d_date AS date,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  )
SELECT cs.date,
       cs.store_net_paid,
       cs.web_net_paid,
       NULL AS catalog_net_loss
FROM combined_sales cs
UNION ALL
SELECT cl.date,
       NULL AS store_net_paid,
       NULL AS web_net_paid,
       cl.catalog_net_loss
FROM catalog_loss_daily cl
ORDER BY date
LIMIT 100
