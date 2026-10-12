WITH state_gender_profit AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(*) AS total_sales
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sales_price > 80
      AND cs.cs_call_center_sk IN (1, 8, 13)
      AND ca.ca_country = 'United States'
      AND cd.cd_credit_rating IN ('AA', 'A')
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ca.ca_state, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    ca_state,
    cd_gender,
    cd_marital_status,
    total_profit,
    avg_discount,
    distinct_orders,
    total_sales,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank_within_gender
FROM state_gender_profit
ORDER BY total_profit DESC
LIMIT 20
