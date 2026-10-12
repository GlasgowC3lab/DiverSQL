WITH agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        CASE
            WHEN hd.hd_buy_potential = 'High' THEN 'HIGH'
            WHEN hd.hd_buy_potential = 'Medium' THEN 'MEDIUM'
            ELSE 'LOW'
        END AS buy_pot_cat,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_buy_potential IS NOT NULL
    GROUP BY
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        CASE
            WHEN hd.hd_buy_potential = 'High' THEN 'HIGH'
            WHEN hd.hd_buy_potential = 'Medium' THEN 'MEDIUM'
            ELSE 'LOW'
        END
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    *,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
