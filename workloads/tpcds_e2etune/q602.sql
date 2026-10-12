WITH state_ship_sales AS (
    SELECT
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        sm.sm_type AS ship_type,
        cs.cs_bill_customer_sk AS bill_customer_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ship_addr_sk IN (5184251, 2121279, 5602324, 4806430)
      AND cs.cs_net_profit <> 0
),
aggregated AS (
    SELECT
        bill_state,
        ship_state,
        ship_type,
        COUNT(DISTINCT bill_customer_sk) AS distinct_customers,
        SUM(net_profit) AS total_net_profit,
        AVG(discount_amount) AS avg_discount_amount,
        ROUND(SUM(net_profit) / NULLIF(SUM(net_paid), 0), 4) AS overall_profit_margin
    FROM state_ship_sales
    GROUP BY bill_state, ship_state, ship_type
    HAVING SUM(net_profit) > 1000
)
SELECT
    bill_state,
    ship_state,
    ship_type,
    distinct_customers,
    total_net_profit,
    avg_discount_amount,
    overall_profit_margin,
    RANK() OVER (PARTITION BY ship_type ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
