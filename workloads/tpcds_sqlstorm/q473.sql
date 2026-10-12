WITH
store_sales_agg AS (
    SELECT 'store' AS channel,
           ss.ss_store_sk AS entity_id,
           d.d_date AS d_date,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
catalog_sales_agg AS (
    SELECT 'catalog' AS channel,
           cs.cs_catalog_page_sk AS entity_id,
           d.d_date AS d_date,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_sales_agg AS (
    SELECT 'web' AS channel,
           ws.ws_web_site_sk AS entity_id,
           d.d_date AS d_date,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
all_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
aggregated_sales AS (
    SELECT channel,
           entity_id,
           d_date,
           sum(net_paid) AS total_net_paid,
           sum(net_profit) AS total_net_profit
    FROM all_sales
    GROUP BY channel, entity_id, d_date
),
store_returns_agg AS (
    SELECT 'store' AS channel,
           sr.sr_store_sk AS entity_id,
           d.d_date AS d_date,
           sum(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, d.d_date
),
catalog_returns_agg AS (
    SELECT 'catalog' AS channel,
           cr.cr_catalog_page_sk AS entity_id,
           d.d_date AS d_date,
           sum(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_catalog_page_sk, d.d_date
),
web_returns_agg AS (
    SELECT 'web' AS channel,
           wr.wr_web_page_sk AS entity_id,
           d.d_date AS d_date,
           sum(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY wr.wr_web_page_sk, d.d_date
),
all_returns AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
sales_with_returns AS (
    SELECT s.channel,
           s.entity_id,
           s.d_date,
           s.total_net_paid,
           s.total_net_profit,
           COALESCE(r.net_loss, 0) AS total_net_loss,
           s.total_net_profit - COALESCE(r.net_loss, 0) AS net_profit_adj,
           s.total_net_paid - COALESCE(r.net_loss, 0) AS net_paid_adj
    FROM aggregated_sales s
    LEFT JOIN all_returns r
      ON s.channel = r.channel
         AND s.entity_id = r.entity_id
         AND s.d_date = r.d_date
),
with_change AS (
    SELECT *,
           lag(net_profit_adj) OVER (PARTITION BY channel, entity_id ORDER BY d_date) AS prev_profit_adj,
           CASE
               WHEN lag(net_profit_adj) OVER (PARTITION BY channel, entity_id ORDER BY d_date) = 0 THEN NULL
               WHEN lag(net_profit_adj) OVER (PARTITION BY channel, entity_id ORDER BY d_date) IS NULL THEN NULL
               ELSE ((net_profit_adj - lag(net_profit_adj) OVER (PARTITION BY channel, entity_id ORDER BY d_date))
                     / lag(net_profit_adj) OVER (PARTITION BY channel, entity_id ORDER BY d_date)) * 100
           END AS profit_change_pct,
           rank() OVER (PARTITION BY channel, d_date ORDER BY net_profit_adj DESC) AS rank_by_profit
    FROM sales_with_returns
)
SELECT wc.channel,
       CASE WHEN wc.channel = 'store' THEN s.s_store_name
            WHEN wc.channel = 'catalog' THEN cp.cp_description
            WHEN wc.channel = 'web' THEN w.web_name
       END AS entity_name,
       CASE WHEN wc.channel = 'store' THEN s.s_city
            WHEN wc.channel = 'catalog' THEN cp.cp_department
            WHEN wc.channel = 'web' THEN w.web_city
       END AS entity_location,
       wc.d_date,
       wc.net_profit_adj,
       wc.profit_change_pct,
       wc.rank_by_profit,
       CASE WHEN wc.profit_change_pct > 10 THEN 'Significant Increase' ELSE 'Normal' END AS profit_trend_flag,
       concat(
           COALESCE(s.s_state, cp.cp_type, w.web_state),
           '-',
           COALESCE(s.s_zip, CAST(cp.cp_catalog_number AS varchar), w.web_zip)
       ) AS location_code,
       CASE WHEN wc.net_profit_adj IS NULL THEN 'No Profit' ELSE 'Profit' END AS profit_status,
       lower(
           CASE WHEN wc.channel = 'store' THEN s.s_store_name
                WHEN wc.channel = 'catalog' THEN cp.cp_description
                WHEN wc.channel = 'web' THEN w.web_name
           END
       ) AS entity_name_lower,
       (SELECT max(net_profit_adj)
        FROM with_change wc2
        WHERE wc2.channel = wc.channel AND wc2.entity_id = wc.entity_id) AS max_entity_profit,
       CASE WHEN regexp_like(
                CASE WHEN wc.channel = 'store' THEN s.s_store_name
                     WHEN wc.channel = 'catalog' THEN cp.cp_description
                     WHEN wc.channel = 'web' THEN w.web_name
                END, '^A.*')
            THEN 1 ELSE 0 END AS starts_with_A_flag
FROM with_change wc
LEFT JOIN store s ON wc.channel = 'store' AND wc.entity_id = s.s_store_sk
LEFT JOIN catalog_page cp ON wc.channel = 'catalog' AND wc.entity_id = cp.cp_catalog_page_sk
LEFT JOIN web_site w ON wc.channel = 'web' AND wc.entity_id = w.web_site_sk
WHERE (wc.profit_change_pct > 10 OR wc.rank_by_profit <= 5)
  AND wc.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
ORDER BY wc.channel, wc.d_date DESC, wc.rank_by_profit
LIMIT 100
