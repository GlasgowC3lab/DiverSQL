-- Goal: Identify high‑value transactions in 2001, combining catalog and store channels, flagging profitability or return status, and enriching each row with a correlated count of related returns and an exploded sales/value array.
WITH catalog_part AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        cs.cs_order_number AS transaction_id,
        cs.cs_ext_sales_price AS amount,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS flag,
        (
            SELECT SUM(cr.cr_return_quantity)
            FROM catalog_returns cr
            WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
        ) AS related_qty,
        t.sales_val AS sales_val
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(ARRAY[cs.cs_ext_sales_price, cs.cs_ext_discount_amt]) AS t(sales_val)
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr WHERE cr.cr_order_number = cs.cs_order_number
      )
),
store_part AS (
    SELECT
        COALESCE(d_sales.d_year, d_ret.d_year) AS year,
        c.c_customer_id AS customer_id,
        COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS transaction_id,
        COALESCE(ss.ss_net_paid, 0) - COALESCE(sr.sr_return_amt, 0) AS amount,
        CASE WHEN sr.sr_ticket_number IS NULL THEN 'NO_RETURN' ELSE 'RETURNED' END AS flag,
        (
            SELECT SUM(sr2.sr_return_quantity)
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
        ) AS related_qty,
        CAST(NULL AS decimal(7,2)) AS sales_val
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_ret   ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN customer c ON (
        ss.ss_customer_sk = c.c_customer_sk OR sr.sr_customer_sk = c.c_customer_sk
    )
    WHERE COALESCE(d_sales.d_year, d_ret.d_year) = 2001
      AND c.c_preferred_cust_flag = 'Y'
)
,
unioned AS (
    SELECT year, customer_id, transaction_id, amount, flag, related_qty, sales_val
    FROM catalog_part
    UNION
    SELECT year, customer_id, transaction_id, amount, flag, related_qty, sales_val
    FROM store_part
)
SELECT
    year,
    customer_id,
    transaction_id,
    amount,
    flag,
    related_qty,
    sales_val
FROM unioned
ORDER BY amount DESC
LIMIT 100
