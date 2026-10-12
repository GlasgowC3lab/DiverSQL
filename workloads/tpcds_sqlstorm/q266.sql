WITH
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        d.d_year AS year,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year, ss.ss_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        d.d_year AS year,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_year, ws.ws_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year AS year,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year, cs.cs_item_sk
),
all_sales AS (
    SELECT cust_sk, year, item_sk, net_profit, net_paid, 'store' AS channel FROM store_sales_agg
    UNION ALL
    SELECT cust_sk, year, item_sk, net_profit, net_paid, 'web' AS channel FROM web_sales_agg
    UNION ALL
    SELECT cust_sk, year, item_sk, net_profit, net_paid, 'catalog' AS channel FROM catalog_sales_agg
),
store_returns_agg AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        d.d_year AS year,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_year, sr.sr_item_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        d.d_year AS year,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_refunded_customer_sk, d.d_year, wr.wr_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS cust_sk,
        d.d_year AS year,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_refunded_customer_sk, d.d_year, cr.cr_item_sk
),
all_returns AS (
    SELECT cust_sk, year, item_sk, net_loss FROM store_returns_agg
    UNION ALL
    SELECT cust_sk, year, item_sk, net_loss FROM web_returns_agg
    UNION ALL
    SELECT cust_sk, year, item_sk, net_loss FROM catalog_returns_agg
),
sales_with_returns AS (
    SELECT
        s.cust_sk,
        s.year,
        s.item_sk,
        s.channel,
        s.net_profit,
        s.net_paid,
        COALESCE(r.net_loss, 0) AS net_loss,
        s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_adj,
        s.net_paid - COALESCE(r.net_loss, 0) AS net_paid_adj
    FROM all_sales s
    LEFT JOIN all_returns r
        ON s.cust_sk = r.cust_sk
        AND s.year = r.year
        AND s.item_sk = r.item_sk
),
cust_year_agg AS (
    SELECT
        cust_sk,
        year,
        SUM(net_profit_adj) AS total_net_profit,
        SUM(net_paid_adj) AS total_net_paid,
        COUNT(DISTINCT item_sk) AS distinct_items
    FROM sales_with_returns
    GROUP BY cust_sk, year
),
cust_year_ranked AS (
    SELECT
        cust_sk,
        year,
        total_net_profit,
        total_net_paid,
        distinct_items,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank,
        LAG(total_net_profit) OVER (PARTITION BY cust_sk ORDER BY year) AS prev_year_profit
    FROM cust_year_agg
),
top_item_per_cust_year AS (
    SELECT
        cust_sk,
        year,
        item_sk,
        channel,
        net_profit_adj
    FROM (
        SELECT
            cust_sk,
            year,
            item_sk,
            channel,
            net_profit_adj,
            ROW_NUMBER() OVER (PARTITION BY cust_sk, year ORDER BY net_profit_adj DESC) AS rn
        FROM sales_with_returns
        WHERE net_profit_adj > 0
    ) t
    WHERE rn = 1
),
joined AS (
    SELECT
        cyr.cust_sk,
        cyr.year,
        cyr.total_net_profit,
        cyr.total_net_paid,
        cyr.distinct_items,
        cyr.profit_rank,
        cyr.prev_year_profit,
        ti.item_sk,
        ti.channel AS top_channel,
        ti.net_profit_adj AS top_item_net_profit,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        c.c_customer_id,
        cd.cd_credit_rating
    FROM cust_year_ranked cyr
    LEFT JOIN top_item_per_cust_year ti
        ON cyr.cust_sk = ti.cust_sk
        AND cyr.year = ti.year
    LEFT JOIN customer c
        ON c.c_customer_sk = cyr.cust_sk
    LEFT JOIN item i
        ON i.i_item_sk = ti.item_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cyr.profit_rank <= 10
      AND (LOWER(COALESCE(cd.cd_credit_rating, 'UNKNOWN')) = 'good' OR cd.cd_credit_rating IS NULL)
)
SELECT
    CONCAT(COALESCE(j.c_first_name, ''), ' ', COALESCE(j.c_last_name, '')) AS customer_name,
    j.c_customer_id,
    j.year,
    j.total_net_profit,
    j.total_net_paid,
    ROUND(j.total_net_profit / NULLIF(j.total_net_paid, 0), 4) AS profit_margin,
    j.profit_rank,
    COALESCE(j.prev_year_profit, 0) AS prev_year_profit,
    j.total_net_profit - COALESCE(j.prev_year_profit, 0) AS profit_change,
    CASE
        WHEN j.prev_year_profit IS NULL THEN 'NEW'
        WHEN j.total_net_profit > j.prev_year_profit THEN 'UP'
        WHEN j.total_net_profit < j.prev_year_profit THEN 'DOWN'
        ELSE 'FLAT'
    END AS trend,
    j.i_item_desc AS top_item_desc,
    j.top_item_net_profit,
    j.top_channel,
    COALESCE(j.cd_credit_rating, 'UNKNOWN') AS credit_rating,
    CASE
        WHEN LOWER(COALESCE(j.cd_credit_rating, '')) = 'good' THEN 'Preferred'
        ELSE 'Standard'
    END AS customer_segment,
    length(CONCAT(COALESCE(j.c_first_name, ''), COALESCE(j.c_last_name, ''))) AS name_length,
    CASE
        WHEN LOWER(j.c_customer_id) LIKE '%smith%' THEN 'SMITH'
        ELSE 'OTHER'
    END AS customer_category,
    (SELECT COALESCE(SUM(r.net_loss), 0) FROM all_returns r
        WHERE r.cust_sk = j.cust_sk AND r.item_sk = j.item_sk) AS total_item_return_loss
FROM joined j
ORDER BY j.year, j.profit_rank
