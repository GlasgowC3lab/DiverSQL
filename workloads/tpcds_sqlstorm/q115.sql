SELECT
    d.d_year,
    s.s_state,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    s.s_state,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY total_net_paid DESC
LIMIT 100
