WITH date_q AS (
    SELECT d_date_sk,
           d_quarter_name
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2000
),
sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_quarter_name AS quarter,
        'catalog' AS channel,
        SUM(cs.cs_net_paid_inc_tax) AS sales_amount,
        SUM(cs.cs_ext_discount_amt) AS discount_amount
    FROM catalog_sales cs
    JOIN date_q d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_quarter_name
    UNION ALL
    SELECT
        ss.ss_item_sk,
        d.d_quarter_name,
        'store',
        SUM(ss.ss_net_paid_inc_tax),
        SUM(ss.ss_ext_discount_amt)
    FROM store_sales ss
    JOIN date_q d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, d.d_quarter_name
    UNION ALL
    SELECT
        ws.ws_item_sk,
        d.d_quarter_name,
        'web',
        SUM(ws.ws_net_paid_inc_tax),
        SUM(ws.ws_ext_discount_amt)
    FROM web_sales ws
    JOIN date_q d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_quarter_name
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d.d_quarter_name AS quarter,
        'catalog' AS channel,
        SUM(cr.cr_return_amt_inc_tax) AS return_amount
    FROM catalog_returns cr
    JOIN date_q d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_item_sk, d.d_quarter_name
    UNION ALL
    SELECT
        sr.sr_item_sk,
        d.d_quarter_name,
        'store',
        SUM(sr.sr_return_amt_inc_tax)
    FROM store_returns sr
    JOIN date_q d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_item_sk, d.d_quarter_name
    UNION ALL
    SELECT
        wr.wr_item_sk,
        d.d_quarter_name,
        'web',
        SUM(wr.wr_return_amt_inc_tax)
    FROM web_returns wr
    JOIN date_q d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_item_sk, d.d_quarter_name
),
sales_returns AS (
    SELECT
        s.item_sk,
        s.quarter,
        s.channel,
        COALESCE(s.sales_amount, 0) - COALESCE(r.return_amount, 0) AS net_revenue,
        COALESCE(s.discount_amount, 0) AS discount_amount
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.item_sk = r.item_sk
        AND s.quarter = r.quarter
        AND s.channel = r.channel
),
category_agg AS (
    SELECT
        i.i_category AS category,
        sr.channel,
        sr.quarter,
        SUM(sr.net_revenue) AS total_net_revenue,
        SUM(sr.discount_amount) AS total_discount
    FROM sales_returns sr
    JOIN item i ON sr.item_sk = i.i_item_sk
    GROUP BY i.i_category, sr.channel, sr.quarter
),
ranked_category AS (
    SELECT
        ca.*,
        ROW_NUMBER() OVER (PARTITION BY ca.channel, ca.quarter ORDER BY ca.total_net_revenue DESC) AS rank,
        SUM(ca.total_net_revenue) OVER (PARTITION BY ca.channel, ca.quarter) AS quarter_total_rev
    FROM category_agg ca
)
SELECT
    channel,
    quarter,
    category,
    total_net_revenue,
    total_discount,
    rank,
    ROUND(100.0 * total_net_revenue / quarter_total_rev, 2) AS revenue_pct
FROM ranked_category
WHERE rank <= 10
ORDER BY channel, quarter, rank
