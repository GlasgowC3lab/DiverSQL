/* Goal: Identify high‑loss web return activity by item category and customer gender for customers whose email ends with '@example.com', living in cities starting with 'New' and ZIP codes beginning with '489'. The query demonstrates string processing, set operations (EXCEPT, INTERSECT), DISTINCT usage, a scalar subquery, aggregation, ordering, a ROW_NUMBER window function, and limits the result to the top 100 rows. */
WITH rc AS (
    SELECT DISTINCT
        wr.wr_returning_customer_sk AS cust_sk,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        i.i_item_sk AS item_sk,
        i.i_category,
        i.i_product_name,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        t.t_hour,
        ca.ca_city,
        ca.ca_zip
    FROM web_returns wr
    JOIN customer c               ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN item i                   ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t               ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND ca.ca_city LIKE 'New%'
      AND SUBSTRING(ca.ca_zip FROM 1 FOR 3) = '489'
      AND regexp_extract(i.i_product_name, '\\d+$') IS NOT NULL
),
rf AS (
    SELECT DISTINCT
        wr.wr_refunded_customer_sk AS cust_sk,
        c.c_email_address
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.org$')
),
high_loss_cust AS (
    SELECT DISTINCT
        wr.wr_returning_customer_sk AS cust_sk
    FROM web_returns wr
    WHERE wr.wr_net_loss > 100
),
-- customers present in rc but not in rf
diff_cust AS (
    SELECT cust_sk FROM rc
    EXCEPT
    SELECT cust_sk FROM rf
),
-- customers that are both in the difference set and have high loss returns
eligible_cust AS (
    SELECT cust_sk FROM diff_cust
    INTERSECT
    SELECT cust_sk FROM high_loss_cust
)
SELECT
    i.i_category,
    rc.cd_gender,
    COUNT(DISTINCT rc.cust_sk) AS distinct_customers,
    SUM(rc.wr_return_amt) AS total_return_amount,
    (SELECT AVG(wr_return_amt) FROM web_returns) AS avg_return_amount_overall,
    ROW_NUMBER() OVER (ORDER BY SUM(rc.wr_return_amt) DESC) AS category_rank
FROM rc
JOIN eligible_cust ec ON rc.cust_sk = ec.cust_sk
JOIN item i ON rc.item_sk = i.i_item_sk
GROUP BY i.i_category, rc.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
