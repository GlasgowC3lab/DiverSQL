WITH sales_agg AS (
    SELECT
        d.d_quarter_name AS quarter,
        cd.cd_gender AS gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS txn_cnt,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year = 2001
        AND d.d_quarter_name IN ('1903Q3', '1903Q2')
        AND d.d_following_holiday = 'N'
        AND cd.cd_credit_rating = 'Good'
        AND cd.cd_dep_count >= 1
        AND cd.cd_dep_college_count <= 2
        AND ss.ss_ext_list_price > (
            SELECT MAX(ss2.ss_ext_list_price)
            FROM store_sales ss2
            WHERE ss2.ss_quantity > 5
        )
    GROUP BY d.d_quarter_name, cd.cd_gender
)
SELECT
    quarter,
    gender,
    total_sales,
    avg_discount,
    txn_cnt,
    total_profit,
    total_sales / NULLIF(txn_cnt, 0) AS avg_sales_per_txn
FROM sales_agg
WHERE total_profit > 0
ORDER BY total_sales DESC, quarter
LIMIT 100
