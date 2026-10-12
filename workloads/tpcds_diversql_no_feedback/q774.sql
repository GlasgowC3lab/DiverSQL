WITH
    filtered_sales AS (
        SELECT
            cs_bill_customer_sk,
            cs_bill_addr_sk,
            cs_bill_cdemo_sk,
            cs_bill_hdemo_sk,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cs_quantity) AS total_qty,
            COUNT(*) AS order_cnt
        FROM catalog_sales
        WHERE cs_ext_list_price > 1000
          AND cs_quantity > 0
          AND cs_net_paid_inc_ship > 500
          AND cs_ext_discount_amt < 1000
          AND cs_ext_tax BETWEEN 0 AND 500
          AND cs_ext_ship_cost < 200
        GROUP BY cs_bill_customer_sk, cs_bill_addr_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk
    ),
    high_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_list_price > 20000
    ),
    low_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_list_price < 5000
    ),
    excluded_orders AS (
        SELECT cs_order_number FROM high_orders
        EXCEPT
        SELECT cs_order_number FROM low_orders
    ),
    valid_customers AS (
        SELECT DISTINCT cs_bill_customer_sk
        FROM catalog_sales
        WHERE cs_order_number IN (SELECT cs_order_number FROM excluded_orders)
    )
SELECT
    ca.ca_state,
    ca.ca_county,
    cd.cd_gender,
    hd.hd_buy_potential,
    agg.total_sales,
    agg.total_qty,
    agg.order_cnt,
    CASE
        WHEN agg.total_sales > 50000 THEN 'Platinum'
        WHEN agg.total_sales > 20000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY agg.total_sales DESC) AS state_sales_rank
FROM filtered_sales agg
JOIN customer_address ca
    ON agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON agg.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_county = 'York County'
  AND cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_buy_potential = 'high'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs_ship
        WHERE cs_ship.cs_ship_addr_sk = ca.ca_address_sk
          AND cs_ship.cs_ext_list_price > 15000
    )
  AND agg.cs_bill_customer_sk IN (SELECT cs_bill_customer_sk FROM valid_customers)
ORDER BY agg.total_sales DESC
LIMIT 100
