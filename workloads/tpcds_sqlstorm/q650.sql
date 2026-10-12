WITH
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MAX(cs.cs_sold_date_sk) AS latest_date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        MAX(ss.ss_sold_date_sk) AS latest_date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MAX(ws.ws_sold_date_sk) AS latest_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
all_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
sales_totals AS (
    SELECT
        customer_sk,
        year,
        SUM(net_paid) AS net_paid,
        SUM(net_profit) AS net_profit,
        SUM(order_cnt) AS orders,
        MAX(latest_date_sk) AS latest_date_sk
    FROM all_sales
    GROUP BY customer_sk, year
),
catalog_returns_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_net_loss) AS return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_refunded_customer_sk, d.d_year
),
store_returns_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_year
),
web_returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(wr.wr_return_amt) AS return_amount,
        SUM(wr.wr_net_loss) AS return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
all_returns AS (
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
returns_totals AS (
    SELECT
        customer_sk,
        year,
        SUM(return_amount) AS return_amount,
        SUM(return_loss) AS return_loss
    FROM all_returns
    GROUP BY customer_sk, year
),
customers_no_sales AS (
    SELECT customer_sk
    FROM returns_totals
    EXCEPT
    SELECT customer_sk
    FROM sales_totals
),
avg_net_paid_per_customer AS (
    SELECT
        customer_sk,
        AVG(net_paid) AS avg_net_paid
    FROM sales_totals
    GROUP BY customer_sk
),
customer_sales_returns AS (
    SELECT
        COALESCE(st.customer_sk, rt.customer_sk) AS customer_sk,
        COALESCE(st.year, rt.year) AS year,
        COALESCE(st.net_paid, 0) AS net_paid,
        COALESCE(st.net_profit, 0) AS net_profit,
        COALESCE(rt.return_amount, 0) AS return_amount,
        COALESCE(rt.return_loss, 0) AS return_loss,
        COALESCE(st.orders, 0) AS orders,
        COALESCE(st.latest_date_sk, 0) AS latest_date_sk
    FROM sales_totals st
    FULL OUTER JOIN returns_totals rt
        ON st.customer_sk = rt.customer_sk AND st.year = rt.year
),
final_metrics AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_customer_sk,
        csr.year,
        csr.net_paid,
        csr.net_profit,
        csr.return_amount,
        csr.return_loss,
        CASE
            WHEN csr.net_paid - csr.return_amount = 0 THEN NULL
            ELSE csr.net_paid - csr.return_amount
        END AS net_paid_minus_returns,
        SUM(csr.net_paid) OVER (PARTITION BY c.c_customer_sk ORDER BY csr.year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY csr.net_paid DESC) AS rn_by_net_paid,
        anp.avg_net_paid AS avg_net_paid_all_years,
        (SELECT AVG(st2.net_paid) FROM sales_totals st2 WHERE st2.customer_sk = c.c_customer_sk) AS corr_avg_net_paid,
        CASE
            WHEN csr.net_profit > 0 THEN 'POSITIVE'
            WHEN csr.net_profit < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_flag,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE WHEN COALESCE(csr.net_paid,0) - COALESCE(csr.return_amount,0) > 1000 THEN TRUE ELSE FALSE END AS high_value_customer,
        CASE WHEN cn.customer_sk IS NOT NULL THEN TRUE ELSE FALSE END AS return_without_sale_flag,
        CASE
            WHEN lower(c.c_email_address) LIKE '%@example.com' THEN 'EXAMPLE'
            ELSE substring(c.c_email_address FROM position('@' IN c.c_email_address) + 1)
        END AS email_domain,
        EXISTS (
            SELECT 1
            FROM sales_totals st_big
            WHERE st_big.customer_sk = c.c_customer_sk
              AND st_big.year = csr.year
              AND st_big.net_paid > 5000
        ) AS has_large_purchase_this_year
    FROM customer c
    LEFT JOIN customer_sales_returns csr ON c.c_customer_sk = csr.customer_sk
    LEFT JOIN avg_net_paid_per_customer anp ON c.c_customer_sk = anp.customer_sk
    LEFT JOIN customers_no_sales cn ON c.c_customer_sk = cn.customer_sk
    WHERE (csr.net_paid - csr.return_amount) > 0
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND (lower(c.c_email_address) LIKE '%@example.com' OR c.c_email_address IS NOT NULL)
      AND EXISTS (
          SELECT 1
          FROM sales_totals st_exists
          WHERE st_exists.customer_sk = c.c_customer_sk
            AND st_exists.net_paid > 1000
      )
)
SELECT *
FROM final_metrics
WHERE rn_by_net_paid <= 5
ORDER BY net_paid_minus_returns DESC
LIMIT 200
