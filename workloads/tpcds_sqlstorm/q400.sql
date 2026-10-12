WITH
    customer_sales AS (
        SELECT
            c.c_customer_sk,
            CONCAT('CUST', LPAD(CAST(c.c_customer_sk AS VARCHAR), 8, '0')) AS customer_code,
            CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
            ca.ca_state AS state,
            'store' AS sales_channel,
            SUM(ss.ss_net_profit) AS net_profit,
            SUM(ss.ss_net_paid) AS net_paid,
            SUM(ss.ss_quantity) AS quantity,
            COUNT(*) AS txn_count,
            MAX(d.d_date) AS last_sales_date
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            ca.ca_state
        UNION ALL
        SELECT
            c.c_customer_sk,
            CONCAT('CUST', LPAD(CAST(c.c_customer_sk AS VARCHAR), 8, '0')) AS customer_code,
            CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
            ca.ca_state AS state,
            'catalog' AS sales_channel,
            SUM(cs.cs_net_profit) AS net_profit,
            SUM(cs.cs_net_paid) AS net_paid,
            SUM(cs.cs_quantity) AS quantity,
            COUNT(*) AS txn_count,
            MAX(d.d_date) AS last_sales_date
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            ca.ca_state
        UNION ALL
        SELECT
            c.c_customer_sk,
            CONCAT('CUST', LPAD(CAST(c.c_customer_sk AS VARCHAR), 8, '0')) AS customer_code,
            CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
            ca.ca_state AS state,
            'web' AS sales_channel,
            SUM(ws.ws_net_profit) AS net_profit,
            SUM(ws.ws_net_paid) AS net_paid,
            SUM(ws.ws_quantity) AS quantity,
            COUNT(*) AS txn_count,
            MAX(d.d_date) AS last_sales_date
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            ca.ca_state
    ),
    returns_union AS (
        SELECT sr_customer_sk AS c_customer_sk, SUM(sr_net_loss) AS return_loss
        FROM store_returns
        GROUP BY sr_customer_sk
        UNION ALL
        SELECT cr_refunded_customer_sk, SUM(cr_net_loss)
        FROM catalog_returns
        GROUP BY cr_refunded_customer_sk
        UNION ALL
        SELECT wr_refunded_customer_sk, SUM(wr_net_loss)
        FROM web_returns
        GROUP BY wr_refunded_customer_sk
    ),
    customer_returns AS (
        SELECT c_customer_sk, SUM(return_loss) AS total_return_loss
        FROM returns_union
        GROUP BY c_customer_sk
    ),
    customer_total_sales AS (
        SELECT
            c_customer_sk,
            customer_code,
            full_name,
            state,
            SUM(net_profit) AS total_net_profit,
            SUM(net_paid) AS total_net_paid,
            SUM(quantity) AS total_quantity,
            SUM(txn_count) AS total_txn_count,
            MAX(last_sales_date) AS most_recent_sales_date
        FROM customer_sales
        GROUP BY
            c_customer_sk,
            customer_code,
            full_name,
            state
    ),
    final_with_returns AS (
        SELECT
            c.c_customer_sk,
            COALESCE(cts.customer_code, CONCAT('CUST', LPAD(CAST(c.c_customer_sk AS VARCHAR), 8, '0'))) AS customer_code,
            COALESCE(cts.full_name, CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, ''))) AS full_name,
            COALESCE(cts.state, ca.ca_state) AS state,
            COALESCE(cts.total_net_profit, 0) AS total_net_profit,
            COALESCE(cts.total_net_paid, 0) AS total_net_paid,
            COALESCE(cts.total_quantity, 0) AS total_quantity,
            COALESCE(cts.total_txn_count, 0) AS total_txn_count,
            cts.most_recent_sales_date,
            COALESCE(cr.total_return_loss, 0) AS total_return_loss,
            (COALESCE(cts.total_net_profit, 0) - COALESCE(cr.total_return_loss, 0)) AS net_profit_after_returns,
            CASE
                WHEN COALESCE(cts.total_net_profit, 0) > 10000 THEN 'Platinum'
                WHEN COALESCE(cts.total_net_profit, 0) > 5000 THEN 'Gold'
                WHEN COALESCE(cts.total_net_profit, 0) > 1000 THEN 'Silver'
                ELSE 'Bronze'
            END AS profit_tier
        FROM customer c
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN customer_total_sales cts ON c.c_customer_sk = cts.c_customer_sk
        LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.c_customer_sk
    ),
    final_ranked AS (
        SELECT
            cwr.c_customer_sk,
            cwr.customer_code,
            cwr.full_name,
            cwr.state,
            cwr.total_net_profit,
            cwr.total_net_paid,
            cwr.total_quantity,
            cwr.total_txn_count,
            cwr.most_recent_sales_date,
            cwr.total_return_loss,
            cwr.net_profit_after_returns,
            cwr.profit_tier,
            ROW_NUMBER() OVER (PARTITION BY cwr.state ORDER BY cwr.net_profit_after_returns DESC) AS rank_within_state,
            RANK() OVER (ORDER BY cwr.net_profit_after_returns DESC) AS overall_rank,
            (SELECT AVG(f2.net_profit_after_returns) FROM final_with_returns f2 WHERE f2.state = cwr.state) AS state_avg_profit,
            (cwr.net_profit_after_returns - (SELECT AVG(f3.net_profit_after_returns) FROM final_with_returns f3 WHERE f3.state = cwr.state)) AS profit_vs_state_avg,
            CASE WHEN cwr.total_net_paid = 0 THEN NULL ELSE cwr.net_profit_after_returns / cwr.total_net_paid END AS profit_margin
        FROM final_with_returns cwr
    )
SELECT
    f.c_customer_sk,
    f.customer_code,
    f.full_name,
    f.state,
    f.total_net_profit,
    f.total_return_loss,
    f.net_profit_after_returns,
    f.profit_tier,
    f.rank_within_state,
    f.overall_rank,
    CAST(f.state_avg_profit AS double) AS state_avg_profit,
    ROUND(f.profit_vs_state_avg, 2) AS profit_vs_state_avg,
    ROUND(f.profit_margin, 4) AS profit_margin,
    f.total_quantity,
    f.total_txn_count,
    f.most_recent_sales_date
FROM final_ranked f
WHERE f.state IS NOT NULL
  AND (f.profit_tier = 'Gold' OR f.net_profit_after_returns > 5000)
ORDER BY f.overall_rank
LIMIT 100
