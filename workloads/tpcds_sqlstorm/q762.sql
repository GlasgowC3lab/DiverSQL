WITH store_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(*) AS store_txns
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(*) AS web_txns
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(*) AS catalog_txns
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
store_ret_agg AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        d.d_year,
        SUM(sr.sr_net_loss) AS store_return_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_quantity,
        COUNT(*) AS store_return_txns
    FROM store_returns sr
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_year
),
catalog_ret_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        d.d_year,
        SUM(cr.cr_net_loss) AS catalog_return_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_quantity,
        COUNT(*) AS catalog_return_txns
    FROM catalog_returns cr
    LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_returning_customer_sk, d.d_year
),
web_ret_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        d.d_year,
        SUM(wr.wr_net_loss) AS web_return_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_quantity,
        COUNT(*) AS web_return_txns
    FROM web_returns wr
    LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
total_sales AS (
    SELECT
        COALESCE(sa.cust_sk, wa.cust_sk, ca.cust_sk) AS cust_sk,
        COALESCE(sa.d_year, wa.d_year, ca.d_year) AS d_year,
        COALESCE(sa.store_net_profit, 0) 
            + COALESCE(wa.web_net_profit, 0) 
            + COALESCE(ca.catalog_net_profit, 0) 
            - COALESCE(sra.store_return_net_loss, 0) 
            - COALESCE(cra.catalog_return_net_loss, 0) 
            - COALESCE(wra.web_return_net_loss, 0) AS total_net_profit,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) + COALESCE(ca.catalog_quantity, 0) AS total_quantity,
        COALESCE(sa.store_txns, 0) + COALESCE(wa.web_txns, 0) + COALESCE(ca.catalog_txns, 0) AS total_txns,
        COALESCE(sra.store_return_quantity, 0) + COALESCE(cra.catalog_return_quantity, 0) + COALESCE(wra.web_return_quantity, 0) AS total_return_qty
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
        ON sa.cust_sk = wa.cust_sk AND sa.d_year = wa.d_year
    FULL OUTER JOIN catalog_agg ca
        ON COALESCE(sa.cust_sk, wa.cust_sk) = ca.cust_sk AND COALESCE(sa.d_year, wa.d_year) = ca.d_year
    LEFT JOIN store_ret_agg sra
        ON COALESCE(sa.cust_sk, wa.cust_sk, ca.cust_sk) = sra.cust_sk AND COALESCE(sa.d_year, wa.d_year, ca.d_year) = sra.d_year
    LEFT JOIN catalog_ret_agg cra
        ON COALESCE(sa.cust_sk, wa.cust_sk, ca.cust_sk) = cra.cust_sk AND COALESCE(sa.d_year, wa.d_year, ca.d_year) = cra.d_year
    LEFT JOIN web_ret_agg wra
        ON COALESCE(sa.cust_sk, wa.cust_sk, ca.cust_sk) = wra.cust_sk AND COALESCE(sa.d_year, wa.d_year, ca.d_year) = wra.d_year
),
cust_sales AS (
    SELECT
        ts.cust_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ts.d_year,
        ts.total_net_profit,
        ts.total_quantity,
        ts.total_txns,
        ts.total_return_qty,
        CASE
            WHEN ts.total_net_profit > 10000 THEN 'high'
            WHEN ts.total_net_profit > 0 THEN 'medium'
            ELSE 'low'
        END AS profit_category,
        CONCAT(UPPER(c.c_first_name), ' ', UPPER(c.c_last_name)) AS full_name_upper,
        CAST(ts.total_net_profit AS varchar) AS total_net_profit_str,
        COALESCE(NULLIF(ts.total_quantity, 0), 1) AS quantity_nonzero
    FROM total_sales ts
    LEFT JOIN customer c ON ts.cust_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ts.cust_sk IS NOT NULL
),
avg_gender_year AS (
    SELECT
        d_year,
        cd_gender,
        AVG(total_net_profit) AS avg_net_profit_gy
    FROM cust_sales
    GROUP BY d_year, cd_gender
),
ranked_customers AS (
    SELECT
        cs.*,
        RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_net_profit DESC) AS rank_by_year,
        RANK() OVER (PARTITION BY cs.d_year, cs.cd_gender ORDER BY cs.total_net_profit DESC) AS rank_by_year_gender,
        AVG(cs.total_net_profit) OVER (PARTITION BY cs.cust_sk ORDER BY cs.d_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3yr,
        (SELECT COUNT(*) FROM cust_sales cs2
         WHERE cs2.d_year = cs.d_year
           AND cs2.cd_gender = cs.cd_gender
           AND cs2.total_net_profit > cs.total_net_profit) AS higher_profit_customers_cnt
    FROM cust_sales cs
),
summary_per_year AS (
    SELECT
        d_year,
        'ALL' AS cd_gender,
        COUNT(DISTINCT cust_sk) AS num_customers,
        SUM(total_net_profit) AS total_profit,
        AVG(total_net_profit) AS avg_profit,
        MAX(total_net_profit) AS max_profit,
        MIN(total_net_profit) AS min_profit,
        'summary' AS record_type
    FROM cust_sales
    GROUP BY d_year
)
SELECT
    rc.cust_sk,
    rc.c_customer_id,
    rc.full_name_upper AS customer_name,
    rc.d_year,
    rc.cd_gender,
    rc.total_net_profit,
    rc.profit_category,
    rc.rank_by_year,
    rc.rank_by_year_gender,
    rc.moving_avg_3yr,
    rc.higher_profit_customers_cnt,
    agg.avg_net_profit_gy,
    format('Profit %.2f in %s', rc.total_net_profit, rc.d_year) AS profit_desc,
    NULL AS record_type
FROM ranked_customers rc
LEFT JOIN avg_gender_year agg
    ON rc.d_year = agg.d_year AND rc.cd_gender = agg.cd_gender
UNION ALL
SELECT
    NULL,
    NULL,
    NULL,
    sp.d_year,
    sp.cd_gender,
    sp.total_profit,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    format('Year %s summary: total profit %.2f', sp.d_year, sp.total_profit),
    sp.record_type
FROM summary_per_year sp
ORDER BY d_year DESC, total_net_profit DESC NULLS LAST
LIMIT 200
