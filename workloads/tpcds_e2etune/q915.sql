WITH demo_sales AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        COUNT(*) AS transaction_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND ss.ss_quantity > 1
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_credit_rating,
    total_net_sales,
    avg_discount_amt,
    transaction_cnt,
    distinct_tickets,
    RANK() OVER (ORDER BY total_net_sales DESC) AS sales_rank,
    total_net_sales / SUM(total_net_sales) OVER () AS sales_share
FROM demo_sales
WHERE total_net_sales > 5000
ORDER BY sales_rank
LIMIT 20
