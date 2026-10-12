WITH
store_agg AS (
    SELECT
        ss_customer_sk AS customer_sk,
        d.d_year AS sales_year,
        SUM(ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss_customer_sk, d.d_year
),
catalog_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        d.d_year AS sales_year,
        SUM(cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
web_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        d.d_year AS sales_year,
        SUM(ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
store_ret AS (
    SELECT
        sr_customer_sk AS customer_sk,
        d.d_year AS sales_year,
        SUM(sr_net_loss) AS store_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_year
),
catalog_ret AS (
    SELECT
        cr_returning_customer_sk AS customer_sk,
        d.d_year AS sales_year,
        SUM(cr_net_loss) AS catalog_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_returning_customer_sk, d.d_year
),
web_ret AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        d.d_year AS sales_year,
        SUM(wr_net_loss) AS web_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
base AS (
    SELECT customer_sk, sales_year FROM store_agg
    UNION
    SELECT customer_sk, sales_year FROM catalog_agg
    UNION
    SELECT customer_sk, sales_year FROM web_agg
),
combined AS (
    SELECT
        b.customer_sk,
        b.sales_year,
        COALESCE(sa.store_profit, 0) + COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0)
        - COALESCE(sr.store_loss, 0) - COALESCE(cr.catalog_loss, 0) - COALESCE(wr.web_loss, 0) AS net_profit
    FROM base b
    LEFT JOIN store_agg sa ON b.customer_sk = sa.customer_sk AND b.sales_year = sa.sales_year
    LEFT JOIN catalog_agg ca ON b.customer_sk = ca.customer_sk AND b.sales_year = ca.sales_year
    LEFT JOIN web_agg wa ON b.customer_sk = wa.customer_sk AND b.sales_year = wa.sales_year
    LEFT JOIN store_ret sr ON b.customer_sk = sr.customer_sk AND b.sales_year = sr.sales_year
    LEFT JOIN catalog_ret cr ON b.customer_sk = cr.customer_sk AND b.sales_year = cr.sales_year
    LEFT JOIN web_ret wr ON b.customer_sk = wr.customer_sk AND b.sales_year = wr.sales_year
),
ranked AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cm.sales_year AS year,
        cm.net_profit,
        ROW_NUMBER() OVER (PARTITION BY cm.sales_year ORDER BY cm.net_profit DESC) AS rank
    FROM combined cm
    JOIN customer c ON cm.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cm.net_profit IS NOT NULL
)
SELECT
    year,
    rank,
    c_customer_id,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    net_profit
FROM ranked
WHERE rank <= 10
ORDER BY year, rank
