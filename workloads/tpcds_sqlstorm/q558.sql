WITH sales_union AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS sale_date_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_item_sk AS item_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_customer_sk AS customer_sk,
           ss.ss_sold_date_sk AS sale_date_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_item_sk AS item_sk,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_sold_date_sk AS sale_date_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_item_sk AS item_sk,
           'web' AS channel
    FROM web_sales ws
), customer_sales AS (
    SELECT
        customer_sk,
        MIN(sale_date_sk) AS first_sale_date_sk,
        MAX(sale_date_sk) AS last_sale_date_sk,
        SUM(net_paid) AS total_sales,
        SUM(net_profit) AS total_profit,
        MAX(item_sk) AS max_sales_item,
        SUM(CASE WHEN channel = 'catalog' THEN net_paid ELSE 0 END) AS catalog_sales,
        SUM(CASE WHEN channel = 'store' THEN net_paid ELSE 0 END) AS store_sales,
        SUM(CASE WHEN channel = 'web' THEN net_paid ELSE 0 END) AS web_sales
    FROM sales_union
    WHERE customer_sk IS NOT NULL
    GROUP BY customer_sk
), date_info AS (
    SELECT
        d_date_sk,
        d_date,
        d_year,
        d_weekend,
        d_day_name
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2002
), recent_returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        MAX(sr.sr_returned_date_sk) AS last_return_date_sk,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN sr.sr_net_loss > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_return_loss
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
), web_return_counts AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk
), cust_addr AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), enriched_sales AS (
    SELECT
        cs.customer_sk,
        cs.first_sale_date_sk,
        cs.last_sale_date_sk,
        cs.total_sales,
        cs.total_profit,
        cs.max_sales_item,
        cs.catalog_sales,
        cs.store_sales,
        cs.web_sales,
        d.d_date AS last_sale_date,
        d.d_year AS last_sale_year,
        COALESCE(rr.last_return_date_sk, -1) AS last_return_date_sk,
        COALESCE(rr.return_cnt, 0) AS return_cnt,
        COALESCE(rr.total_return_loss, 0) AS total_return_loss,
        COALESCE(wrc.web_return_cnt, 0) AS web_return_cnt,
        ca.ca_city,
        ca.ca_state
    FROM customer_sales cs
    FULL OUTER JOIN date_info d ON cs.last_sale_date_sk = d.d_date_sk
    LEFT JOIN recent_returns rr ON cs.customer_sk = rr.customer_sk
    LEFT JOIN web_return_counts wrc ON cs.customer_sk = wrc.customer_sk
    LEFT JOIN cust_addr ca ON cs.customer_sk = ca.c_customer_sk
), final_ranked AS (
    SELECT
        es.*,
        CASE
            WHEN es.total_profit IS NULL OR es.total_profit = 0 THEN NULL
            ELSE es.total_sales / es.total_profit
        END AS sales_to_profit_ratio,
        CASE
            WHEN es.total_sales > 20000 THEN 'Platinum'
            WHEN es.total_sales > 10000 THEN 'Gold'
            WHEN es.total_sales > 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier,
        ROW_NUMBER() OVER (
            PARTITION BY
                CASE
                    WHEN es.total_sales > 20000 THEN 'Platinum'
                    WHEN es.total_sales > 10000 THEN 'Gold'
                    WHEN es.total_sales > 5000 THEN 'Silver'
                    ELSE 'Bronze'
                END
            ORDER BY es.total_sales DESC
        ) AS tier_rank,
        COUNT(*) OVER (PARTITION BY es.last_sale_year) AS customers_in_year,
        LAG(es.last_sale_date) OVER (
            PARTITION BY
                CASE
                    WHEN es.total_sales > 20000 THEN 'Platinum'
                    WHEN es.total_sales > 10000 THEN 'Gold'
                    WHEN es.total_sales > 5000 THEN 'Silver'
                    ELSE 'Bronze'
                END
            ORDER BY es.total_sales DESC
        ) AS prev_last_sale_date,
        (SELECT MAX(ws2.ws_quantity)
         FROM web_sales ws2
         WHERE ws2.ws_bill_customer_sk = es.customer_sk) AS max_web_quantity
    FROM enriched_sales es
    WHERE (es.total_sales IS NOT NULL OR es.total_profit IS NOT NULL)
      AND (es.last_sale_year IS NULL OR es.last_sale_year BETWEEN 1999 AND 2002)
      AND (es.return_cnt = 0 OR es.return_cnt IS NULL OR es.total_return_loss < 1000)
), customer_details AS (
    SELECT
        fr.customer_sk,
        COALESCE(c.c_first_name, 'UNKNOWN') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
        fr.total_sales,
        fr.total_profit,
        fr.sales_to_profit_ratio,
        fr.tier,
        fr.tier_rank,
        fr.customers_in_year,
        fr.last_sale_date,
        fr.last_sale_year,
        fr.return_cnt,
        fr.web_return_cnt,
        CASE
            WHEN fr.return_cnt > 0 THEN 'HasReturn'
            ELSE 'NoReturn'
        END AS return_flag,
        CONCAT('CODE-', SUBSTR(fr.tier, 1, 1), '-', LPAD(CAST(fr.customer_sk AS VARCHAR), 6, '0')) AS tier_code,
        COALESCE(NULLIF(fr.total_sales, 0), 0) / NULLIF(fr.sales_to_profit_ratio + 0.0001, 1) AS adjusted_metric,
        fr.total_return_loss,
        fr.ca_city,
        fr.ca_state,
        fr.max_web_quantity,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM store_returns sr2
                WHERE sr2.sr_customer_sk = fr.customer_sk
                  AND sr2.sr_returned_date_sk = fr.last_return_date_sk
            ) THEN 'ReturnExists' ELSE 'NoReturnRecord'
        END AS return_exists_flag
    FROM final_ranked fr
    LEFT JOIN customer c ON fr.customer_sk = c.c_customer_sk
    WHERE fr.tier_rank <= 5
), top_customers AS (
    SELECT *
    FROM customer_details
    WHERE tier_rank <= 3
), summary_row AS (
    SELECT
        -1 AS customer_sk,
        'TOTAL_SUMMARY' AS full_name,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit,
        AVG(sales_to_profit_ratio) AS sales_to_profit_ratio,
        'SUMMARY' AS tier,
        NULL AS tier_rank,
        NULL AS customers_in_year,
        NULL AS last_sale_date,
        NULL AS last_sale_year,
        NULL AS return_cnt,
        NULL AS web_return_cnt,
        NULL AS return_flag,
        NULL AS tier_code,
        NULL AS adjusted_metric,
        SUM(total_return_loss) AS total_return_loss,
        NULL AS ca_city,
        NULL AS ca_state,
        NULL AS max_web_quantity,
        NULL AS return_exists_flag
    FROM customer_details
    WHERE tier_rank <= 5
    GROUP BY tier
    HAVING SUM(total_sales) > 0
)
SELECT *
FROM top_customers
UNION ALL
SELECT *
FROM summary_row
ORDER BY tier DESC NULLS LAST, total_sales DESC
LIMIT 100
