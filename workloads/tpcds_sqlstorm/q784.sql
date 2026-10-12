WITH catalog_sales_agg AS (
    SELECT d.d_year AS year,
           cc.cc_state AS state,
           i.i_category AS category,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           0.0 AS total_returns,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, cc.cc_state, i.i_category
),
catalog_returns_agg AS (
    SELECT d.d_year AS year,
           cc.cc_state AS state,
           i.i_category AS category,
           0.0 AS total_sales,
           SUM(cr.cr_return_amount) AS total_returns,
           -SUM(cr.cr_net_loss) AS total_profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, cc.cc_state, i.i_category
),
store_sales_agg AS (
    SELECT d.d_year AS year,
           s.s_state AS state,
           i.i_category AS category,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           0.0 AS total_returns,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, s.s_state, i.i_category
),
store_returns_agg AS (
    SELECT d.d_year AS year,
           s.s_state AS state,
           i.i_category AS category,
           0.0 AS total_sales,
           SUM(sr.sr_return_amt) AS total_returns,
           -SUM(sr.sr_net_loss) AS total_profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, s.s_state, i.i_category
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           ws_site.web_state AS state,
           i.i_category AS category,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           0.0 AS total_returns,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, ws_site.web_state, i.i_category
),
web_returns_agg AS (
    SELECT d.d_year AS year,
           'WEB' AS state,
           i.i_category AS category,
           0.0 AS total_sales,
           SUM(wr.wr_return_amt) AS total_returns,
           -SUM(wr.wr_net_loss) AS total_profit
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
)
SELECT year,
       state,
       category,
       SUM(total_sales) AS total_sales,
       SUM(total_returns) AS total_returns,
       SUM(total_sales) - SUM(total_returns) AS net_sales,
       SUM(total_profit) AS total_profit
FROM (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM web_returns_agg
) AS agg
GROUP BY year, state, category
ORDER BY year, state, category
