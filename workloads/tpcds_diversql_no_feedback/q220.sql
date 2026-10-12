WITH joined AS (
    SELECT
        cc.cc_name AS cc_name,
        ib.ib_income_band_sk AS ib_income_band_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_ext_list_price,
        ws.ws_net_profit,
        ws.ws_ext_ship_cost
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_tax_percentage = 0.03
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_ext_list_price > 5000
      AND ib.ib_lower_bound >= 50000
      AND hd.hd_vehicle_count > 2
      AND ws.ws_net_profit > 0
)
SELECT
    cc_name,
    ib_income_band_sk,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(ws_net_profit) AS avg_net_profit,
    MIN(cs_ext_discount_amt) AS min_discount,
    MAX(ws_ext_ship_cost) AS max_ship_cost,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(cs_net_paid) DESC) AS rank_by_sales
FROM joined
GROUP BY cc_name, ib_income_band_sk
ORDER BY total_net_paid DESC
LIMIT 100
