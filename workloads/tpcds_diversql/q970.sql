WITH full_cust_demo AS (
        SELECT c.c_customer_sk,
               c.c_customer_id,
               c.c_first_name,
               c.c_last_name,
               c.c_birth_month,
               cd.cd_gender,
               cd.cd_dep_count
        FROM tpcds.customer c
        FULL OUTER JOIN tpcds.customer_demographics cd
          ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ),
    union_store AS (
        SELECT sr.sr_store_sk AS store_sk,
               SUM(sr.sr_return_amt) AS total_return_amt
        FROM tpcds.store_returns sr
        WHERE sr.sr_return_ship_cost > 200
        GROUP BY sr.sr_store_sk
        UNION
        SELECT s.s_store_sk AS store_sk,
               CAST(0.0 AS DOUBLE) AS total_return_amt
        FROM tpcds.store s
        WHERE s.s_state = 'TX'
    ),
    intersect_customers AS (
        SELECT sr.sr_customer_sk AS cust_sk
        FROM tpcds.store_returns sr
        WHERE sr.sr_return_quantity > 2
        INTERSECT
        SELECT c.c_customer_sk
        FROM tpcds.customer c
        WHERE c.c_birth_year BETWEEN 1980 AND 2000
    )
SELECT
    fcd.c_customer_id,
    fcd.c_first_name,
    fcd.c_last_name,
    fcd.cd_gender,
    s.s_store_name,
    sr.sr_return_amt,
    SUM(sr.sr_return_amt) OVER (
        PARTITION BY s.s_store_name
        ORDER BY sr.sr_returned_date_sk
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS rolling_sum_2,
    DENSE_RANK() OVER (
        PARTITION BY s.s_state
        ORDER BY sr.sr_return_amt DESC
    ) AS state_rank,
    CASE WHEN fcd.cd_dep_count = 0 THEN 'No Dep' ELSE 'Has Dep' END AS dep_flag
FROM tpcds.store_returns sr
RIGHT OUTER JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN full_cust_demo fcd
    ON sr.sr_customer_sk = fcd.c_customer_sk
WHERE s.s_country = 'United States'
  AND sr.sr_return_amt > 150
  AND sr.sr_return_tax BETWEEN 5 AND 50
  AND fcd.c_birth_month = 7
  AND fcd.cd_gender = 'M'
  AND fcd.c_customer_sk IN (SELECT cust_sk FROM intersect_customers)
  AND s.s_store_sk IN (SELECT store_sk FROM union_store)
ORDER BY sr.sr_return_amt DESC
OFFSET 20 ROWS
LIMIT 100
