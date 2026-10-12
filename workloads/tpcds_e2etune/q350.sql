WITH profit_by_demo AS (
    SELECT
        hd.hd_income_band_sk AS income_band,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd.cd_gender = 'F'
      AND hd.hd_vehicle_count >= 2
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ss.ss_quantity > 1
    GROUP BY hd.hd_income_band_sk, cd.cd_gender, cd.cd_education_status
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    income_band,
    gender,
    education,
    total_profit,
    avg_discount,
    num_tickets,
    RANK() OVER (PARTITION BY income_band ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_demo
ORDER BY total_profit DESC
LIMIT 20
