WITH returns_agg AS (
   SELECT
       d.d_year AS year,
       ws.web_mkt_id AS market_id,
       SUM(wr.wr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE regexp_like(ws.web_zip, '^9[0-9]{4}$')
     AND ws.web_name LIKE '%Shop%'
   GROUP BY d.d_year, ws.web_mkt_id
),
site_agg AS (
   SELECT
       ws.web_mkt_id AS market_id,
       substr(ws.web_zip, 1, 3) AS zip_prefix,
       COUNT(*) AS site_cnt,
       concat('Market_', CAST(ws.web_mkt_id AS varchar)) AS market_label
   FROM web_site ws
   JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
   WHERE ws.web_zip LIKE '8%'
   GROUP BY ws.web_mkt_id, substr(ws.web_zip, 1, 3)
),
full_data AS (
   SELECT
       COALESCE(r.market_id, s.market_id) AS market_id,
       r.year,
       r.total_net_loss,
       r.return_cnt,
       s.zip_prefix,
       s.site_cnt,
       s.market_label
   FROM returns_agg r
   FULL OUTER JOIN site_agg s
     ON r.market_id = s.market_id
)
SELECT
   market_id,
   year,
   total_net_loss,
   return_cnt,
   zip_prefix,
   site_cnt,
   market_label
FROM full_data
WHERE market_id NOT IN (
   SELECT DISTINCT web_mkt_id FROM web_site WHERE web_state = 'CA'
)
UNION
SELECT
   market_id,
   year,
   total_net_loss,
   return_cnt,
   zip_prefix,
   site_cnt,
   market_label
FROM full_data
WHERE zip_prefix IS NOT NULL
ORDER BY market_id
LIMIT 100
