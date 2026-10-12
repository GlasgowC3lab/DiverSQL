WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE ss_ext_wholesale_cost > 500
          AND ss_ext_list_price BETWEEN 300 AND 8000
          AND ss_quantity >= 1
          AND ss_net_profit > 0
          AND ss_ticket_number <> 635558
          AND ss_ext_discount_amt < 1000
    ),
    agg_a AS (
        SELECT
            c.c_birth_country AS birth_country,
            cd.cd_gender AS gender,
            SUM(ss.ss_ext_sales_price) AS sales_sum,
            AVG(ss.ss_net_profit) AS profit_avg
        FROM sampled_sales ss
        FULL OUTER JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE c.c_salutation = 'Mr.'
          AND cd.cd_marital_status = 'M'
          AND c.c_birth_country = 'TURKMENISTAN'
          AND cd.cd_credit_rating = 'C'
          AND ss.ss_ext_tax > 0
          AND ss.ss_ext_discount_amt < 200
        GROUP BY ROLLUP (c.c_birth_country, cd.cd_gender)
    ),
    agg_b AS (
        SELECT
            c.c_birth_country AS birth_country,
            cd.cd_gender AS gender,
            SUM(ss.ss_ext_sales_price) AS sales_sum,
            AVG(ss.ss_net_profit) AS profit_avg
        FROM sampled_sales ss
        FULL OUTER JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE c.c_salutation = 'Mrs.'
          AND cd.cd_marital_status = 'S'
          AND c.c_birth_country = 'GAMBIA'
          AND cd.cd_credit_rating = 'B'
          AND ss.ss_ext_tax > 10
          AND ss.ss_ext_discount_amt BETWEEN 100 AND 500
        GROUP BY ROLLUP (c.c_birth_country, cd.cd_gender)
    ),
    unioned AS (
        SELECT birth_country, gender, sales_sum, profit_avg FROM agg_a
        UNION DISTINCT
        SELECT birth_country, gender, sales_sum, profit_avg FROM agg_b
    ),
    final_agg AS (
        SELECT
            birth_country,
            gender,
            SUM(sales_sum) AS total_sales,
            AVG(profit_avg) AS overall_avg_profit
        FROM unioned
        GROUP BY ROLLUP (birth_country, gender)
    )
SELECT
    birth_country,
    gender,
    total_sales,
    overall_avg_profit
FROM final_agg
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
