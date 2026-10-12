WITH sales_agg AS (
    SELECT
        ss_ticket_number,
        ss_store_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_net_paid_inc_tax)      AS total_net_paid,
        SUM(ss_ext_sales_price)       AS total_sales,
        SUM(ss_ext_discount_amt)      AS total_discount,
        SUM(ss_quantity)              AS total_quantity,
        SUM(ss_net_profit)            AS total_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ss_ticket_number, ss_store_sk, ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    COUNT(DISTINCT s.ss_ticket_number)               AS num_transactions,
    SUM(s.total_profit)                               AS profit_sum,
    AVG(s.total_profit)                               AS profit_avg,
    SUM(s.total_sales)                                AS sales_sum,
    SUM(s.total_discount)                             AS discount_sum,
    SUM(s.total_quantity)                             AS quantity_sum,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(s.total_profit) DESC) AS profit_rank_by_gender
FROM sales_agg s
JOIN customer_demographics cd ON s.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON s.ss_hdemo_sk = hd.hd_demo_sk
WHERE cd.cd_credit_rating = 'Excellent'
  AND hd.hd_vehicle_count >= 2
GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
HAVING SUM(s.total_profit) > 10000
ORDER BY profit_sum DESC
LIMIT 100
