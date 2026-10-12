WITH sales_base AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_order_number AS order_number,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_net_profit AS profit,
           cs.cs_call_center_sk AS call_center_sk,
           'Catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_customer_sk AS cust_sk,
           ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_ticket_number AS order_number,
           ss.ss_ext_sales_price AS sales_amount,
           ss.ss_net_profit AS profit,
           CAST(NULL AS integer) AS call_center_sk,
           'Store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_sold_date_sk AS sold_date_sk,
           ws.ws_order_number AS order_number,
           ws.ws_ext_sales_price AS sales_amount,
           ws.ws_net_profit AS profit,
           CAST(NULL AS integer) AS call_center_sk,
           'Web' AS channel
    FROM web_sales ws
),
returns_base AS (
    SELECT cr.cr_returning_customer_sk AS cust_sk,
           cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss,
           'Catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_customer_sk AS cust_sk,
           sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_return_amt AS return_amount,
           sr.sr_net_loss AS net_loss,
           'Store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_refunded_customer_sk AS cust_sk,
           wr.wr_returned_date_sk AS returned_date_sk,
           wr.wr_return_amt AS return_amount,
           wr.wr_net_loss AS net_loss,
           'Web' AS channel
    FROM web_returns wr
),
customer_info AS (
    SELECT c.c_customer_sk,
           COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
           CASE
               WHEN c.c_birth_year IS NULL OR c.c_birth_month IS NULL OR c.c_birth_day IS NULL THEN NULL
               ELSE CAST(c.c_birth_year AS varchar) || '-' || LPAD(CAST(c.c_birth_month AS varchar), 2, '0') || '-' || LPAD(CAST(c.c_birth_day AS varchar), 2, '0')
           END AS birth_date,
           cd.cd_gender,
           cd.cd_education_status,
           hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
call_center_sales AS (
    SELECT cs.cs_call_center_sk AS cc_sk,
           SUM(cs.cs_ext_sales_price) AS cs_sales,
           SUM(cs.cs_net_profit) AS cs_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk
),
all_call_centers AS (
    SELECT cc.cc_call_center_sk AS cc_sk,
           cc.cc_name,
           cc.cc_gmt_offset
    FROM call_center cc
),
call_center_agg AS (
    SELECT COALESCE(ccs.cc_sk, acc.cc_sk) AS cc_sk,
           acc.cc_name,
           acc.cc_gmt_offset,
           COALESCE(ccs.cs_sales, 0) AS cs_sales,
           COALESCE(ccs.cs_profit, 0) AS cs_profit
    FROM call_center_sales ccs
    FULL OUTER JOIN all_call_centers acc ON ccs.cc_sk = acc.cc_sk
),
store_and_web_customers AS (
    SELECT cust_sk FROM sales_base WHERE channel = 'Store'
    INTERSECT
    SELECT cust_sk FROM sales_base WHERE channel = 'Web'
),
customer_sales_agg AS (
    SELECT
        ci.c_customer_sk,
        ci.full_name,
        ci.birth_date,
        ci.cd_gender,
        ci.cd_education_status,
        ci.hd_income_band_sk,
        SUM(s.sales_amount) AS total_sales_amount,
        SUM(s.profit) AS total_gross_profit,
        SUM(COALESCE(r.return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(r.net_loss, 0)) AS total_return_loss,
        (SUM(s.profit) - SUM(COALESCE(r.net_loss, 0))) AS net_profit_after_returns,
        COUNT(DISTINCT s.channel) AS distinct_channels,
        MAX(d.d_date) AS last_sale_date,
        MAX(ccagg.cs_sales) AS call_center_sales_amount,
        MAX(ccagg.cs_profit) AS call_center_profit_amount
    FROM
        sales_base s
        LEFT JOIN returns_base r
            ON s.cust_sk = r.cust_sk
            AND s.sold_date_sk = r.returned_date_sk
            AND s.channel = r.channel
        INNER JOIN customer_info ci ON s.cust_sk = ci.c_customer_sk
        LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
        LEFT JOIN call_center_agg ccagg ON s.call_center_sk = ccagg.cc_sk
        INNER JOIN store_and_web_customers swc ON ci.c_customer_sk = swc.cust_sk
    WHERE
        (ci.cd_gender = 'M' OR ci.cd_gender IS NULL)
        AND (ci.cd_education_status NOT IN ('College', 'Graduate') OR ci.cd_education_status IS NULL)
        AND (ci.hd_income_band_sk = 5 OR ci.hd_income_band_sk IS NULL)
        AND s.sales_amount > (SELECT AVG(s2.sales_amount) FROM sales_base s2 WHERE s2.channel = s.channel)
        AND (d.d_year = 1999 OR d.d_year IS NULL)
    GROUP BY
        ci.c_customer_sk,
        ci.full_name,
        ci.birth_date,
        ci.cd_gender,
        ci.cd_education_status,
        ci.hd_income_band_sk
    HAVING
        SUM(s.sales_amount) > 1000
)
SELECT
    csa.c_customer_sk,
    csa.full_name,
    csa.birth_date,
    csa.cd_gender,
    csa.cd_education_status,
    csa.hd_income_band_sk,
    csa.total_sales_amount,
    csa.total_gross_profit,
    csa.total_return_amount,
    csa.total_return_loss,
    csa.net_profit_after_returns,
    csa.distinct_channels,
    ROW_NUMBER() OVER (ORDER BY csa.net_profit_after_returns DESC) AS profit_rank,
    CASE
        WHEN csa.total_gross_profit > 0 AND csa.total_return_loss = 0 THEN 'PureProfit'
        WHEN csa.total_gross_profit > 0 AND csa.total_return_loss > 0 THEN 'MixedProfit'
        ELSE 'Loss'
    END AS profit_category,
    csa.last_sale_date,
    (SELECT COUNT(*) FROM returns_base r_sub WHERE r_sub.cust_sk = csa.c_customer_sk AND r_sub.channel = 'Catalog') AS catalog_return_count,
    (SELECT COUNT(*) FROM returns_base r_sub WHERE r_sub.cust_sk = csa.c_customer_sk AND r_sub.channel = 'Store') AS store_return_count,
    (SELECT COUNT(*) FROM returns_base r_sub WHERE r_sub.cust_sk = csa.c_customer_sk AND r_sub.channel = 'Web') AS web_return_count,
    csa.call_center_sales_amount,
    csa.call_center_profit_amount,
    SUM(csa.total_sales_amount) OVER (ORDER BY csa.total_sales_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_amount
FROM
    customer_sales_agg csa
ORDER BY
    csa.net_profit_after_returns DESC
LIMIT 10
