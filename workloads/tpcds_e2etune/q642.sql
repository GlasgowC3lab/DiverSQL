WITH dept_month_sales AS (
    SELECT
        cp.cp_department,
        date_trunc('month', date_add('day', ss.ss_sold_date_sk, date '1970-01-01')) AS sale_month,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM
        store_sales ss
    JOIN
        catalog_page cp
        ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE
        cp.cp_type = 'monthly'
        AND cp.cp_department = 'DEPARTMENT'
        AND ss.ss_quantity >= 1
    GROUP BY
        cp.cp_department,
        date_trunc('month', date_add('day', ss.ss_sold_date_sk, date '1970-01-01'))
    HAVING
        SUM(ss.ss_net_paid) > 5000
)
SELECT
    cp_department,
    sale_month,
    total_net_paid,
    avg_discount_amount,
    distinct_tickets,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_net_paid DESC) AS dept_month_rank
FROM
    dept_month_sales
ORDER BY
    cp_department,
    dept_month_rank
LIMIT 20
