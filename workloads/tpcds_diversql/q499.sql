WITH
    sales_agg AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
          AND ss.ss_ext_sales_price > 1000
          AND ss.ss_quantity >= 1
          AND ss.ss_list_price BETWEEN 10 AND 200
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
    ),
    sales_joined AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            s.s_state,
            s.s_number_employees,
            sa.total_sales,
            sa.total_profit,
            sa.sales_cnt,
            CASE WHEN sa.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
        FROM store s
        FULL OUTER JOIN sales_agg sa
            ON s.s_store_sk = sa.ss_store_sk
        WHERE s.s_state IN ('CA', 'TX')
          AND s.s_number_employees > 50
    ),
    loss_stores AS (
        SELECT s_store_sk
        FROM sales_joined
        WHERE profit_flag = 'Loss'
    ),
    union_set AS (
        SELECT
            sj.s_store_sk,
            sj.s_store_name,
            sj.s_state,
            sj.total_sales,
            sj.total_profit,
            r.r_reason_desc,
            sj.profit_flag,
            hd.hd_buy_potential,
            ca.ca_city,
            cd.cd_gender,
            SUM(sj.total_sales) OVER (PARTITION BY sj.s_state ORDER BY sj.total_sales DESC
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_by_state
        FROM sales_joined sj
        JOIN store_returns sr
            ON sj.s_store_sk = sr.sr_store_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE r.r_reason_desc LIKE '%damaged%'
          AND hd.hd_buy_potential = '500-1000'
          AND ca.ca_city = 'Springfield'
          AND cd.cd_gender = 'M'
        UNION
        SELECT
            s.s_store_sk,
            s.s_store_name,
            s.s_state,
            0.0 AS total_sales,
            0.0 AS total_profit,
            COALESCE(r.r_reason_desc, 'No Return') AS r_reason_desc,
            'No Sales' AS profit_flag,
            hd.hd_buy_potential,
            ca.ca_city,
            cd.cd_gender,
            NULL AS running_sales_by_state
        FROM store s
        LEFT JOIN store_returns sr
            ON s.s_store_sk = sr.sr_store_sk
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE sr.sr_store_sk IS NULL
          AND hd.hd_buy_potential = '501-1000'
          AND ca.ca_city = 'Fairview'
          AND cd.cd_gender = 'F'
    ),
    final_set AS (
        SELECT *
        FROM union_set
        EXCEPT
        SELECT *
        FROM union_set us
        WHERE us.profit_flag = 'Loss'
    )
SELECT
    f.s_store_sk,
    f.s_store_name,
    f.s_state,
    f.total_sales,
    f.total_profit,
    f.r_reason_desc,
    f.profit_flag,
    f.hd_buy_potential,
    f.ca_city,
    f.cd_gender,
    f.running_sales_by_state
FROM final_set f
GROUP BY
    f.s_store_sk,
    f.s_store_name,
    f.s_state,
    f.total_sales,
    f.total_profit,
    f.r_reason_desc,
    f.profit_flag,
    f.hd_buy_potential,
    f.ca_city,
    f.cd_gender,
    f.running_sales_by_state
HAVING SUM(f.total_sales) > 5000
ORDER BY f.total_sales DESC
LIMIT 100
