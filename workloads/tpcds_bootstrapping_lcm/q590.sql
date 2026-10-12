SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month_key,
    s.s_state AS store_state,
    p.p_purpose AS promotion_purpose,
    CASE 
        WHEN wr.wr_return_quantity <= 5 THEN 'Small'
        WHEN wr.wr_return_quantity <= 20 THEN 'Medium'
        ELSE 'Large'
    END AS return_quantity_bucket,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_promo_cost,
    SUM(s.s_tax_percentage) AS total_store_tax_percentage,
    COUNT(DISTINCT cust_returning.c_customer_id) AS distinct_returning_customers,
    COUNT(DISTINCT cust_refunded.c_customer_id) AS distinct_refunded_customers,
    AVG(date_diff('day', d_cust_sales.d_date, d_ret.d_date)) AS avg_days_since_first_sale,
    AVG(date_diff('day', d_cust_ship.d_date, d_ret.d_date)) AS avg_days_since_first_ship,
    MIN(d_ret.d_date) AS earliest_return_date,
    MAX(d_ret.d_date) AS latest_return_date
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN customer cust_returning
    ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
JOIN customer cust_refunded
    ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
LEFT JOIN date_dim d_cust_sales
    ON cust_returning.c_first_sales_date_sk = d_cust_sales.d_date_sk
LEFT JOIN date_dim d_cust_ship
    ON cust_returning.c_first_shipto_date_sk = d_cust_ship.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    p.p_purpose,
    CASE 
        WHEN wr.wr_return_quantity <= 5 THEN 'Small'
        WHEN wr.wr_return_quantity <= 20 THEN 'Medium'
        ELSE 'Large'
    END
HAVING SUM(wr.wr_return_amt) > 0
ORDER BY total_net_loss DESC
LIMIT 100
