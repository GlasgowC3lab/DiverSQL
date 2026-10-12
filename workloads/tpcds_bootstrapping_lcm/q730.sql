SELECT
    s.s_store_id,
    CONCAT(CAST(d_sales.d_year AS VARCHAR), '-', LPAD(CAST(d_sales.d_moy AS VARCHAR), 2, '0')) AS sales_year_month,
    CASE
        WHEN c_bill.c_birth_month BETWEEN 1 AND 3 THEN 'Q1_birth'
        WHEN c_bill.c_birth_month BETWEEN 4 AND 6 THEN 'Q2_birth'
        WHEN c_bill.c_birth_month BETWEEN 7 AND 9 THEN 'Q3_birth'
        ELSE 'Q4_birth'
    END AS birth_quarter,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_bill_customers,
    COUNT(DISTINCT c_ship.c_customer_sk) AS distinct_ship_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount,
    SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS total_return_quantity,
    MAX(d_return.d_date) AS latest_return_date,
    SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(*), 0) AS avg_sales_per_transaction,
    SUM(CASE WHEN ws.ws_ext_sales_price > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS sales_txn_ratio,
    SUM(CASE WHEN wr.wr_return_quantity > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS return_txn_ratio
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_store.d_date_sk
JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_cust_shipto ON c_bill.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
LEFT JOIN date_dim d_cust_sales ON c_bill.c_first_sales_date_sk = d_cust_sales.d_date_sk
GROUP BY
    s.s_store_id,
    d_sales.d_year,
    d_sales.d_moy,
    CASE
        WHEN c_bill.c_birth_month BETWEEN 1 AND 3 THEN 'Q1_birth'
        WHEN c_bill.c_birth_month BETWEEN 4 AND 6 THEN 'Q2_birth'
        WHEN c_bill.c_birth_month BETWEEN 7 AND 9 THEN 'Q3_birth'
        ELSE 'Q4_birth'
    END
ORDER BY s.s_store_id, sales_year_month, birth_quarter
LIMIT 100
