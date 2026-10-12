WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        t.t_sub_shift AS sub_shift,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
        COUNT(*) AS transaction_cnt
    FROM
        store_sales ss
        TABLESAMPLE BERNOULLI (10)
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN web_page wp
            ON c.c_customer_sk = wp.wp_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1970
        AND c.c_preferred_cust_flag = 'Y'
        AND ca.ca_country = 'United States'
        AND i.i_current_price > 20
        AND t.t_hour BETWEEN 6 AND 12
    GROUP BY CUBE (
        ca.ca_state,
        cd.cd_gender,
        i.i_category,
        p.p_promo_name,
        t.t_sub_shift
    )
)
SELECT
    state,
    gender,
    category,
    promo_name,
    sub_shift,
    SUM(total_sales) AS sum_sales,
    AVG(total_qty) AS avg_qty,
    SUM(total_return_amt) AS sum_returns,
    COUNT(transaction_cnt) AS num_groups
FROM sales_agg
WHERE state IS NOT NULL
GROUP BY
    state,
    gender,
    category,
    promo_name,
    sub_shift
HAVING
    SUM(total_sales) > 50000
ORDER BY sum_sales DESC
LIMIT 100
