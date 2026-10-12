WITH profit_by_cust AS (
    SELECT
        c.c_customer_id,
        c.c_birth_month,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        SUM(ss.ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_month ORDER BY SUM(ss.ss_net_profit) DESC) AS drk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        c.c_customer_id,
        c.c_birth_month,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential
)
SELECT
    c_customer_id,
    c_birth_month,
    cd_credit_rating,
    cd_purchase_estimate,
    hd_buy_potential,
    total_profit
FROM profit_by_cust
WHERE drk <= 5
ORDER BY c_birth_month, drk
