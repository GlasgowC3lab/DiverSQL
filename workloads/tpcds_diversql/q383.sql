WITH
    sales_agg AS (
        SELECT
            cs_bill_customer_sk,
            SUM(cs_net_paid)            AS total_paid,
            COUNT(*)                    AS num_sales,
            AVG(cs_net_paid)            AS avg_paid
        FROM catalog_sales
        WHERE cs_sold_date_sk BETWEEN 2450000 AND 2453000        -- sold date range
          AND cs_quantity > 1                                 -- at least two items per row
          AND cs_ext_discount_amt < 100                       -- modest discounts
          AND cs_wholesale_cost > 0                           -- positive cost
          AND cs_list_price > cs_wholesale_cost               -- list price higher than cost
        GROUP BY cs_bill_customer_sk
    ),
    cust_ca AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_current_cdemo_sk,
            c.c_current_hdemo_sk,
            c.c_current_addr_sk,
            ca.ca_gmt_offset,
            ca.ca_state
        FROM customer c
        FULL OUTER JOIN customer_address ca
            ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE (c.c_birth_year BETWEEN 1950 AND 1990)                     -- age filter
          AND (ca.ca_gmt_offset IS NOT NULL OR c.c_preferred_cust_flag = 'Y')
    ),
    qualified_customers AS (
        SELECT cust_key
        FROM (
            SELECT cs_bill_customer_sk AS cust_key
            FROM catalog_sales
            WHERE cs_net_paid > 5000
        )
        INTERSECT
        SELECT cust_key
        FROM (
            SELECT c.c_customer_sk AS cust_key
            FROM customer c
            JOIN household_demographics hd
                ON c.c_current_hdemo_sk = hd.hd_demo_sk
            JOIN income_band ib
                ON hd.hd_income_band_sk = ib.ib_income_band_sk
            WHERE ib.ib_upper_bound >= 90000
        )
    ),
    cross_data AS (
        SELECT ib.ib_upper_bound,
               v.grade
        FROM (
            SELECT DISTINCT ib_upper_bound
            FROM income_band
            WHERE ib_upper_bound >= 50000
        ) ib
        CROSS JOIN (VALUES 'A', 'B') AS v(grade)
    )
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    CASE
        WHEN ib.ib_upper_bound >= 90000 THEN 'High Income'
        WHEN ib.ib_upper_bound >= 50000 THEN 'Mid Income'
        ELSE 'Low Income'
    END                                 AS income_category,
    s.total_paid,
    s.num_sales,
    s.avg_paid,
    cd.cd_credit_rating,
    cd.cd_education_status,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound,
    cd2.grade                                 AS dummy_grade
FROM cust_ca c
LEFT JOIN qualified_customers q
    ON c.c_customer_sk = q.cust_key
JOIN sales_agg s
    ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN cross_data cd2
    ON ib.ib_upper_bound = cd2.ib_upper_bound
WHERE q.cust_key IS NOT NULL                -- keep only intersect‑qualified customers
  AND c.ca_state = 'CA'                      -- state filter
  AND ib.ib_lower_bound >= 50000             -- income lower bound filter
  AND cd.cd_credit_rating = 'Excellent'      -- credit rating filter
  AND hd.hd_vehicle_count > 0                -- vehicle ownership filter
ORDER BY s.total_paid DESC
LIMIT 100
