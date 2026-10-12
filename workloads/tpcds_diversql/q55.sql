WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    c.c_customer_id,
    i.i_item_id,
    i.i_brand,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CASE
        WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown Income'
        ELSE CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR)
    END AS income_band_range,
    SUM(ws.ws_net_paid) AS web_sales_paid,
    SUM(sr.sr_return_amt) AS store_returns_amount
FROM cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND hd.hd_buy_potential = '5001-10000'
  AND cs.cs_quantity > 5
GROUP BY
    d.d_year,
    c.c_customer_id,
    i.i_item_id,
    i.i_brand,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_profit DESC
LIMIT 100
