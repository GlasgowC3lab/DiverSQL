WITH city_sales AS (
    SELECT
        ca.ca_city AS segment,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(ss.ss_ticket_number) AS transaction_count,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    RIGHT OUTER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_dep_count > 2
    )
      AND ca.ca_city IN ('Maple Grove', 'Fairfield', 'Greenville')
    GROUP BY ca.ca_city
)
SELECT segment, total_net_paid, transaction_count, profit_category
FROM city_sales
UNION ALL
SELECT
    cd.cd_gender AS segment,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(ss.ss_ticket_number) AS transaction_count,
    CASE
        WHEN AVG(ss.ss_net_profit) >= 0 THEN 'Non-negative'
        ELSE 'Negative'
    END AS profit_category
FROM store_sales ss
RIGHT OUTER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_addr_sk IN (
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_state = 'CA'
)
  AND cd.cd_education_status = 'Advanced Degree'
GROUP BY cd.cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
