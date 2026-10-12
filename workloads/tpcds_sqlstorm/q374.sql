WITH store_sales_agg AS (
    SELECT d.d_year AS sales_year,
           s.s_state AS state,
           SUM(ss.ss_net_paid) AS sales_net_paid,
           SUM(ss.ss_net_profit) AS sales_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_state
), store_returns_agg AS (
    SELECT d.d_year AS sales_year,
           s.s_state AS state,
           SUM(sr.sr_net_loss) AS returns_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_state
), catalog_sales_agg AS (
    SELECT d.d_year AS sales_year,
           cc.cc_state AS state,
           SUM(cs.cs_net_paid) AS sales_net_paid,
           SUM(cs.cs_net_profit) AS sales_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cc.cc_state
), catalog_returns_agg AS (
    SELECT d.d_year AS sales_year,
           cc.cc_state AS state,
           SUM(cr.cr_net_loss) AS returns_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cc.cc_state
), web_sales_agg AS (
    SELECT d.d_year AS sales_year,
           ws_site.web_state AS state,
           SUM(ws.ws_net_paid) AS sales_net_paid,
           SUM(ws.ws_net_profit) AS sales_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ws_site.web_state
), combined AS (
    SELECT s.sales_year,
           s.state,
           'store' AS channel,
           s.sales_net_paid AS total_sales,
           s.sales_net_profit AS total_profit,
           COALESCE(r.returns_net_loss, 0) AS total_returns,
           s.sales_net_paid - COALESCE(r.returns_net_loss, 0) AS net_after_returns
    FROM store_sales_agg s
    LEFT JOIN store_returns_agg r
      ON s.sales_year = r.sales_year AND s.state = r.state

    UNION ALL

    SELECT c.sales_year,
           c.state,
           'catalog' AS channel,
           c.sales_net_paid AS total_sales,
           c.sales_net_profit AS total_profit,
           COALESCE(r.returns_net_loss, 0) AS total_returns,
           c.sales_net_paid - COALESCE(r.returns_net_loss, 0) AS net_after_returns
    FROM catalog_sales_agg c
    LEFT JOIN catalog_returns_agg r
      ON c.sales_year = r.sales_year AND c.state = r.state

    UNION ALL

    SELECT w.sales_year,
           w.state,
           'web' AS channel,
           w.sales_net_paid AS total_sales,
           w.sales_net_profit AS total_profit,
           0 AS total_returns,
           w.sales_net_paid AS net_after_returns
    FROM web_sales_agg w
)
SELECT
    sales_year,
    state,
    channel,
    total_sales,
    total_profit,
    total_returns,
    net_after_returns,
    ROW_NUMBER() OVER (PARTITION BY sales_year, channel ORDER BY total_sales DESC) AS sales_rank
FROM combined
ORDER BY sales_year, channel, sales_rank
