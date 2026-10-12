WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_refunded_cash,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND cr.cr_refunded_cash > 100
)
SELECT
    sm.sm_type,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(s.cs_net_paid) AS total_sales,
    SUM(r.cr_return_amount) AS total_returns,
    SUM(s.cs_net_profit) AS total_profit,
    ROUND(100.0 * SUM(r.cr_return_amount) / NULLIF(SUM(s.cs_net_paid), 0), 2) AS return_rate_pct,
    AVG(s.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT s.cs_order_number) AS num_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(s.cs_net_profit) DESC) AS profit_rank
FROM sales s
JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE sm.sm_type IN ('AIR', 'RAIL', 'TRUCK')
  AND cd.cd_gender = 'M'
GROUP BY sm.sm_type, cd.cd_gender, cd.cd_marital_status
HAVING SUM(s.cs_net_paid) > 10000
ORDER BY total_profit DESC
LIMIT 10
