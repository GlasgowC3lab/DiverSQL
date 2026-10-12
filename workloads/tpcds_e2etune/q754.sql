SELECT
    cd_sale.cd_gender AS gender,
    cd_sale.cd_marital_status AS marital_status,
    hd_curr.hd_buy_potential AS household_buy_potential,
    CAST(FLOOR(ss.ss_sold_date_sk / 10000) AS INTEGER) AS sale_year,
    COUNT(*) AS transaction_cnt,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customer_cnt,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_sale
    ON ss.ss_cdemo_sk = cd_sale.cd_demo_sk
JOIN household_demographics hd_sale
    ON ss.ss_hdemo_sk = hd_sale.hd_demo_sk
JOIN customer_demographics cd_curr
    ON c.c_current_cdemo_sk = cd_curr.cd_demo_sk
JOIN household_demographics hd_curr
    ON c.c_current_hdemo_sk = hd_curr.hd_demo_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1970
  AND cd_curr.cd_credit_rating = 'Excellent'
  AND hd_curr.hd_buy_potential = 'High'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
  AND ss.ss_quantity > 0
GROUP BY
    cd_sale.cd_gender,
    cd_sale.cd_marital_status,
    hd_curr.hd_buy_potential,
    CAST(FLOOR(ss.ss_sold_date_sk / 10000) AS INTEGER)
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 20
