SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank_by_birth_year
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cd.cd_gender,
    hd.hd_vehicle_count
