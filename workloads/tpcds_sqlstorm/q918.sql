WITH sales AS (
    SELECT
        s.s_store_id AS channel_id,
        d.d_year,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY s.s_store_id, d.d_year, i.i_category
    UNION ALL
    SELECT
        cc.cc_call_center_id AS channel_id,
        d.d_year,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY cc.cc_call_center_id, d.d_year, i.i_category
),
returns AS (
    SELECT
        s.s_store_id AS channel_id,
        d.d_year,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS return_amt,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY s.s_store_id, d.d_year, i.i_category
    UNION ALL
    SELECT
        cc.cc_call_center_id AS channel_id,
        d.d_year,
        i.i_category AS category,
        SUM(cr.cr_refunded_cash) AS return_amt,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY cc.cc_call_center_id, d.d_year, i.i_category
)
SELECT
    s.channel_id,
    s.d_year,
    s.category,
    s.net_paid,
    s.net_profit,
    COALESCE(r.return_amt, 0) AS return_amt,
    COALESCE(r.net_loss, 0) AS net_loss,
    (COALESCE(r.return_amt, 0) / NULLIF(s.net_paid, 0)) * 100 AS return_percent,
    SUM(s.net_profit - COALESCE(r.net_loss, 0)) OVER (PARTITION BY s.channel_id ORDER BY s.d_year, s.category ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
FROM sales s
LEFT JOIN returns r
  ON s.channel_id = r.channel_id
 AND s.d_year = r.d_year
 AND s.category = r.category
ORDER BY s.channel_id, s.d_year, s.category
LIMIT 200
