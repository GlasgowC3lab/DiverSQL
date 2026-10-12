WITH
    refund_agg AS (
        SELECT
            wr_refunded_hdemo_sk AS hd_demo_sk,
            SUM(wr_return_amt_inc_tax) AS total_refund_inc_tax,
            COUNT(*) AS cnt_returns
        FROM web_returns
        WHERE wr_return_quantity > 0
          AND wr_refunded_cash > 0
          AND wr_return_amt > 0
          AND wr_return_tax >= 0
          AND wr_fee >= 0
          AND wr_return_ship_cost >= 0
        GROUP BY wr_refunded_hdemo_sk
    ),
    customer_agg AS (
        SELECT
            c_current_hdemo_sk AS hd_demo_sk,
            COUNT(DISTINCT c_customer_sk) AS num_customers,
            MIN(c_first_sales_date_sk) AS first_sales_date_sk
        FROM customer
        WHERE c_preferred_cust_flag = 'Y'
          AND c_birth_year BETWEEN 1950 AND 1970
          AND c_birth_month IN (1, 2, 3, 4, 5, 6)
          AND c_birth_day BETWEEN 1 AND 15
          AND c_login IS NOT NULL
          AND c_email_address LIKE '%@%'
        GROUP BY c_current_hdemo_sk
    ),
    intersect_demo AS (
        SELECT hd_demo_sk FROM household_demographics
        WHERE hd_buy_potential IN ('1001-5000', '5001-10000')
          AND hd_vehicle_count >= 1
        INTERSECT
        SELECT hd_demo_sk FROM refund_agg
        WHERE total_refund_inc_tax > 1000
    )
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    SUM(ra.total_refund_inc_tax) AS sum_refund_inc_tax,
    SUM(ra.cnt_returns) AS sum_cnt_returns,
    SUM(ca.num_customers) AS sum_num_customers,
    MIN(ca.first_sales_date_sk) AS min_first_sales_date_sk
FROM intersect_demo id
JOIN household_demographics hd ON hd.hd_demo_sk = id.hd_demo_sk
LEFT JOIN refund_agg ra ON ra.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN customer_agg ca ON ca.hd_demo_sk = hd.hd_demo_sk
WHERE hd.hd_dep_count BETWEEN 1 AND 7
  AND hd.hd_vehicle_count <> -1
  AND hd.hd_buy_potential <> 'Unknown'
GROUP BY GROUPING SETS (
    (hd.hd_demo_sk, hd.hd_buy_potential, hd.hd_vehicle_count, hd.hd_dep_count),
    (hd.hd_demo_sk)
)
HAVING SUM(ra.cnt_returns) > 0
ORDER BY hd.hd_demo_sk ASC
LIMIT 100
