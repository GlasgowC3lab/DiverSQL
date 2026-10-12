WITH agg AS (
    SELECT
        hd_bill.hd_buy_potential AS bill_buy_potential,
        hd_ship.hd_buy_potential AS ship_buy_potential,
        cs.cs_ship_mode_sk AS ship_mode,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450826
      AND cs.cs_ship_mode_sk IN (5, 11, 7)
    GROUP BY
        hd_bill.hd_buy_potential,
        hd_ship.hd_buy_potential,
        cs.cs_ship_mode_sk
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 10000
)
SELECT
    bill_buy_potential,
    ship_buy_potential,
    ship_mode,
    order_cnt,
    total_net_paid,
    avg_net_profit,
    RANK() OVER (PARTITION BY bill_buy_potential ORDER BY total_net_paid DESC) AS rank_by_total_paid
FROM agg
ORDER BY total_net_paid DESC
LIMIT 50
