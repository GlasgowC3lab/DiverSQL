WITH
catalog_agg AS (
    SELECT
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid_inc_tax) AS revenue,
        SUM(cs.cs_net_profit) AS profit,
        'Catalog' AS channel
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1220
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk
),
store_agg AS (
    SELECT
        s.s_store_sk AS call_center_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid_inc_tax) AS revenue,
        SUM(ss.ss_net_profit) AS profit,
        'Store' AS channel
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1220
    GROUP BY s.s_store_sk, ss.ss_item_sk
),
web_agg AS (
    SELECT
        w.web_site_sk AS call_center_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS revenue,
        SUM(ws.ws_net_profit) AS profit,
        'Web' AS channel
    FROM web_sales ws
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1220
    GROUP BY w.web_site_sk, ws.ws_item_sk
),
common_items AS (
    SELECT item_sk FROM catalog_agg
    INTERSECT
    SELECT item_sk FROM store_agg
    INTERSECT
    SELECT item_sk FROM web_agg
),
combined_sales AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
),
sales_by_cc AS (
    SELECT
        COALESCE(c.cc_call_center_sk, -1) AS call_center_sk,
        c.cc_name,
        cs.item_sk,
        cs.channel,
        cs.revenue,
        cs.profit,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(c.cc_call_center_sk, -1) ORDER BY cs.revenue DESC NULLS LAST) AS revenue_rank,
        AVG(cs.profit) OVER (PARTITION BY COALESCE(c.cc_call_center_sk, -1)) AS avg_profit,
        cs.profit - AVG(cs.profit) OVER (PARTITION BY COALESCE(c.cc_call_center_sk, -1)) AS profit_vs_avg,
        CASE 
            WHEN cs.revenue IS NULL THEN 'No Sales'
            WHEN cs.revenue >= 100000 THEN 'High'
            ELSE 'Low'
        END AS revenue_category,
        (cs.profit / NULLIF(cs.revenue, 0)) * 100 AS profit_margin_percent,
        (
            SELECT 
                COALESCE(SUM(cr.cr_return_amount), 0)
                + COALESCE(SUM(sr.sr_return_amt), 0)
                + COALESCE(SUM(wr.wr_return_amt), 0)
            FROM catalog_returns cr
            LEFT JOIN store_returns sr
                ON cr.cr_item_sk = sr.sr_item_sk
                AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
            LEFT JOIN web_returns wr
                ON cr.cr_item_sk = wr.wr_item_sk
                AND cr.cr_returned_date_sk = wr.wr_returned_date_sk
            WHERE cr.cr_item_sk = cs.item_sk
        ) AS total_return_amount
    FROM call_center c
    LEFT JOIN combined_sales cs
        ON c.cc_call_center_sk = cs.call_center_sk
        AND cs.item_sk IN (SELECT item_sk FROM common_items)
)
SELECT
    call_center_sk,
    COALESCE(cc_name, 'No Call Center') AS call_center_name,
    item_sk,
    channel,
    revenue,
    profit,
    revenue_rank,
    profit_vs_avg,
    profit_margin_percent,
    total_return_amount,
    revenue_category,
    CONCAT('Rank ', CAST(revenue_rank AS VARCHAR), ': ', COALESCE(cc_name, 'Unknown')) AS label,
    CASE WHEN revenue IS NULL THEN 'Missing' ELSE 'Present' END AS sales_flag
FROM sales_by_cc
WHERE revenue_rank <= 5
  AND revenue IS NOT NULL
ORDER BY call_center_sk, revenue_rank
