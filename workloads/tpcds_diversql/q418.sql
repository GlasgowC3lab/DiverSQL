WITH pref_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END AS income_category,
        (SELECT COUNT(*) FROM customer c2 WHERE c2.c_current_hdemo_sk = c.c_current_hdemo_sk) AS same_hdemo_customer_cnt
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ib.ib_upper_bound >= 150000
      AND EXISTS (
          SELECT 1
          FROM income_band ib2
          WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
            AND ib2.ib_upper_bound > 120000
      )
),
nonpref_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound <= 100000 THEN 'Low' ELSE 'Medium' END AS income_category,
        (SELECT COUNT(*) FROM customer c2 WHERE c2.c_current_hdemo_sk = c.c_current_hdemo_sk) AS same_hdemo_customer_cnt
    FROM customer c
    FULL OUTER JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND ib.ib_upper_bound <= 100000
),
unioned AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_preferred_cust_flag,
        income_category,
        same_hdemo_customer_cnt
    FROM pref_customers
    UNION ALL
    SELECT
        c_customer_sk,
        c_customer_id,
        c_preferred_cust_flag,
        income_category,
        same_hdemo_customer_cnt
    FROM nonpref_customers
)
SELECT
    u.c_customer_id,
    u.c_preferred_cust_flag,
    u.income_category,
    u.same_hdemo_customer_cnt,
    ROW_NUMBER() OVER (ORDER BY u.income_category, u.c_customer_id) AS rn,
    (
        SELECT COUNT(*)
        FROM household_demographics hd
        WHERE hd.hd_demo_sk = COALESCE(u.c_customer_sk, -1)
    ) AS hd_match_count
FROM unioned u
ORDER BY rn
