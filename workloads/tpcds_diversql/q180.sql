WITH pattern_customers AS (
        SELECT c_customer_sk
        FROM customer
        WHERE regexp_like(c_first_name, '^A[[:alpha:]]+')
          AND c_preferred_cust_flag = 'Y'
    ),
    high_return_customers AS (
        SELECT DISTINCT sr_customer_sk AS c_customer_sk
        FROM store_returns
        WHERE sr_return_quantity > 10
    ),
    target_customers AS (
        SELECT c_customer_sk FROM pattern_customers
        INTERSECT
        SELECT c_customer_sk FROM high_return_customers
    )
SELECT
        s.s_store_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_net_profit) AS avg_profit_per_tx,
        SUM(CASE WHEN regexp_like(i.i_item_desc, '(?i).*\b(USB|HDMI)\b.*') THEN ss.ss_net_profit ELSE 0 END) AS profit_usb_hdmi,
        COUNT(DISTINCT CASE WHEN i.i_item_desc LIKE '%Cable%' THEN regexp_extract(i.i_item_desc, '(\\w+)-\\w+', 1) END) AS distinct_brands,
        (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN target_customers tc ON ss.ss_customer_sk = tc.c_customer_sk
WHERE s.s_state = 'CA'
  AND i.i_item_desc LIKE '%Cable%'
GROUP BY s.s_store_name
ORDER BY total_net_profit DESC
LIMIT 100
