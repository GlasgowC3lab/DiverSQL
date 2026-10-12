WITH
    preferred_customers AS (
        SELECT c_customer_sk
        FROM tpcds.customer
        WHERE c_preferred_cust_flag = 'Y'
    ),
    sales AS (
        SELECT
            ss.ss_ticket_number AS ticket,
            cd.cd_gender AS gender,
            CAST(NULL AS varchar) AS reason_desc,
            ss.ss_net_paid AS amount
        FROM tpcds.store_sales ss
        JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE ss.ss_customer_sk IN (SELECT c_customer_sk FROM preferred_customers)
    ),
    returns AS (
        SELECT
            sr.sr_ticket_number AS ticket,
            cd.cd_gender AS gender,
            r.r_reason_desc AS reason_desc,
            sr.sr_return_amt AS amount
        FROM tpcds.store_returns sr
        JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_customer_sk IN (SELECT c_customer_sk FROM preferred_customers)
    ),
    intersect_tickets AS (
        SELECT ticket FROM sales INTERSECT SELECT ticket FROM returns
    ),
    combined AS (
        SELECT ticket, gender, reason_desc, amount FROM sales
        UNION ALL
        SELECT ticket, gender, reason_desc, amount FROM returns
    )
SELECT
    ticket,
    gender,
    reason_desc,
    SUM(amount) AS total_amount,
    CASE WHEN SUM(amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
FROM combined
WHERE ticket IN (SELECT ticket FROM intersect_tickets)
GROUP BY CUBE (gender, reason_desc, ticket)
ORDER BY ticket
LIMIT 100
