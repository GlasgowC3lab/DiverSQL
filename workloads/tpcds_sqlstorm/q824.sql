WITH
sales_union AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_customer_sk AS cust_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        'web' AS channel
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        su.cust_sk,
        d.d_year AS year,
        SUM(su.net_profit) AS sum_profit,
        SUM(su.net_paid) AS sum_paid,
        COUNT(*) AS sales_count,
        SUM(CASE WHEN su.channel = 'store' THEN 1 ELSE 0 END) AS store_sales_cnt,
        SUM(CASE WHEN su.channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_sales_cnt,
        SUM(CASE WHEN su.channel = 'web' THEN 1 ELSE 0 END) AS web_sales_cnt
    FROM sales_union su
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    GROUP BY su.cust_sk, d.d_year
),
returns_union AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_qty
    FROM store_returns sr
    UNION ALL
    SELECT
        cr.cr_refunded_customer_sk AS cust_sk,
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_qty
    FROM web_returns wr
),
returns_agg AS (
    SELECT
        ru.cust_sk,
        d.d_year AS year,
        SUM(ru.net_loss) AS sum_loss,
        COUNT(*) AS return_count,
        SUM(ru.return_qty) AS total_return_qty
    FROM returns_union ru
    JOIN date_dim d ON ru.returned_date_sk = d.d_date_sk
    GROUP BY ru.cust_sk, d.d_year
),
net_agg AS (
    SELECT
        COALESCE(sa.cust_sk, ra.cust_sk) AS cust_sk,
        COALESCE(sa.year, ra.year) AS year,
        COALESCE(sa.sum_profit, 0) - COALESCE(ra.sum_loss, 0) AS net_profit,
        COALESCE(sa.sum_paid, 0) AS total_paid,
        COALESCE(sa.sales_count, 0) AS sales_cnt,
        COALESCE(sa.store_sales_cnt, 0) AS store_sales_cnt,
        COALESCE(sa.catalog_sales_cnt, 0) AS catalog_sales_cnt,
        COALESCE(sa.web_sales_cnt, 0) AS web_sales_cnt,
        COALESCE(ra.return_count, 0) AS return_cnt,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.cust_sk = ra.cust_sk AND sa.year = ra.year
),
cc_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year AS year,
        MAX(cc.cc_manager) AS cc_manager
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
top_category_counts AS (
    SELECT
        su.cust_sk,
        d.d_year AS year,
        i.i_category,
        COUNT(*) AS cnt
    FROM sales_union su
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    GROUP BY su.cust_sk, d.d_year, i.i_category
),
top_category_ranked AS (
    SELECT
        cust_sk,
        year,
        i_category,
        cnt,
        ROW_NUMBER() OVER (PARTITION BY cust_sk, year ORDER BY cnt DESC) AS rn
    FROM top_category_counts
),
top_category_per_customer AS (
    SELECT
        cust_sk,
        year,
        i_category AS top_category
    FROM top_category_ranked
    WHERE rn = 1
)
SELECT
    c.c_customer_id AS customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    n.year,
    n.net_profit,
    n.total_paid,
    n.sales_cnt,
    n.return_cnt,
    n.total_return_qty,
    n.store_sales_cnt,
    n.catalog_sales_cnt,
    n.web_sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY n.year ORDER BY n.net_profit DESC) AS profit_rank,
    NTILE(5) OVER (PARTITION BY n.year ORDER BY n.net_profit DESC) AS profit_quintile,
    CASE WHEN n.total_paid > 0 THEN n.net_profit / n.total_paid ELSE NULL END AS profit_to_paid_ratio,
    CASE WHEN n.net_profit > (SELECT AVG(net_profit) FROM net_agg WHERE year = n.year) THEN 'Y' ELSE 'N' END AS high_value_flag,
    COALESCE(tpc.top_category, 'UNKNOWN') AS top_item_category,
    COALESCE(cc.cc_manager, 'NO_CC') AS call_center_manager,
    CASE
        WHEN cd.cd_credit_rating = 'Excellent' THEN 'HIGH'
        WHEN cd.cd_credit_rating = 'Good' THEN 'MEDIUM'
        ELSE 'NORMAL'
    END AS credit_rating_category,
    CASE WHEN n.return_cnt > n.sales_cnt THEN 1 ELSE 0 END AS returns_exceed_sales_flag
FROM net_agg n
LEFT JOIN customer c ON n.cust_sk = c.c_customer_sk
LEFT JOIN cc_agg cc ON n.cust_sk = cc.cust_sk AND n.year = cc.year
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN top_category_per_customer tpc ON n.cust_sk = tpc.cust_sk AND n.year = tpc.year
WHERE n.year = 2001
ORDER BY n.year, profit_rank
LIMIT 100
