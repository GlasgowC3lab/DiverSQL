WITH filtered_sales AS (
    SELECT
        cs_order_number,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        cs_ship_mode_sk,
        cs_net_profit,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        cs_sales_price,
        cs_quantity,
        cs_ext_ship_cost
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450820 AND 2450845
      AND cs_sales_price > 50.0
      AND cs_ext_ship_cost < 1000.0
      AND cs_quantity > 1
),
agg AS (
    SELECT
        bd.cd_gender AS bill_gender,
        bd.cd_marital_status AS bill_marital_status,
        sd.cd_gender AS ship_gender,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM filtered_sales cs
    JOIN customer_demographics bd
        ON cs.cs_bill_cdemo_sk = bd.cd_demo_sk
    JOIN customer_demographics sd
        ON cs.cs_ship_cdemo_sk = sd.cd_demo_sk
    GROUP BY bd.cd_gender, bd.cd_marital_status, sd.cd_gender, cs.cs_ship_mode_sk
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    bill_gender,
    bill_marital_status,
    ship_gender,
    ship_mode_sk,
    order_cnt,
    total_net_profit,
    total_sales,
    avg_discount,
    total_sales / SUM(total_sales) OVER () AS sales_share,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 20
