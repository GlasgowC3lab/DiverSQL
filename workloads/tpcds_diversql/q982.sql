WITH
    sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_ext_tax,
            cs.cs_net_paid,
            cs.cs_bill_cdemo_sk,
            cs.cs_sold_date_sk,
            ca.ca_state,
            ca.ca_country
        FROM catalog_sales cs
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE cs.cs_bill_cdemo_sk = 1046123
          AND cs.cs_ext_tax > 100
          AND ca.ca_state = 'CA'
    ),
    returns AS (
        SELECT
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_net_loss,
            wr.wr_reason_sk,
            r.r_reason_desc,
            ca.ca_state AS return_state
        FROM web_returns wr
        JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer_address ca
            ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE r.r_reason_desc = 'Gift exchange'
          AND wr.wr_return_amt > 50
    ),
    full_combined AS (
        SELECT
            s.cs_order_number,
            s.cs_ext_tax,
            s.cs_net_paid,
            s.ca_state AS sale_state,
            r.wr_order_number,
            r.wr_return_amt,
            r.return_state
        FROM sales s
        FULL OUTER JOIN returns r
            ON s.cs_order_number = r.wr_order_number
    ),
    order_numbers_sales AS (
        SELECT cs_order_number AS order_number
        FROM catalog_sales
        WHERE cs_bill_cdemo_sk = 1046123
    ),
    order_numbers_returns AS (
        SELECT wr_order_number AS order_number
        FROM web_returns
        WHERE wr_return_amt > 0
    ),
    orders_excluded AS (
        SELECT order_number
        FROM order_numbers_sales
        EXCEPT
        SELECT order_number
        FROM order_numbers_returns
    ),
    filtered AS (
        SELECT *
        FROM full_combined fc
        WHERE EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_order_number = fc.cs_order_number
        )
          AND fc.cs_ext_tax > (
                SELECT MAX(cs_ext_tax)
                FROM catalog_sales
                WHERE cs_bill_cdemo_sk = 1046123
            )
          AND (fc.cs_order_number IS NOT NULL OR fc.wr_order_number IS NOT NULL)
          AND COALESCE(fc.cs_order_number, fc.wr_order_number) NOT IN (SELECT order_number FROM orders_excluded)
    )
SELECT
    COALESCE(sale_state, return_state) AS state,
    COUNT(DISTINCT cs_order_number) AS sales_order_cnt,
    COUNT(DISTINCT wr_order_number) AS return_order_cnt,
    SUM(cs_net_paid) AS total_sales_amount,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(cs_ext_tax) AS avg_sales_tax,
    MAX(cs_ext_tax) AS max_sales_tax
FROM filtered
GROUP BY COALESCE(sale_state, return_state)
ORDER BY total_sales_amount DESC
LIMIT 100
