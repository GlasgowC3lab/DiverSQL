WITH returns_orders AS (
        SELECT DISTINCT wr_order_number
        FROM web_returns
    ),
    sales_data AS (
        SELECT
            cs.cs_bill_customer_sk,
            cs.cs_order_number,
            cs.cs_net_paid_inc_ship_tax,
            cs.cs_net_profit,
            cs.cs_sold_time_sk,
            cs.cs_ship_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_ship_cdemo_sk,
            cs.cs_ship_hdemo_sk
        FROM catalog_sales cs
        WHERE cs.cs_order_number NOT IN (SELECT wr_order_number FROM returns_orders)
    )
SELECT
    c_bill.c_customer_id,
    c_bill.c_first_name,
    c_bill.c_last_name,
    cd_bill.cd_gender,
    hd_bill.hd_buy_potential,
    t_sold.t_hour,
    SUM(s.cs_net_paid_inc_ship_tax) AS total_sales_amount,
    SUM(s.cs_net_profit) AS total_profit,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    COALESCE(SUM(wr_refund.wr_net_loss), 0) AS total_return_loss,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM sales_data s
JOIN time_dim t_sold
    ON s.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill
    ON s.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
    ON s.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
    ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_returns wr_refund
    ON c_bill.c_customer_sk = wr_refund.wr_refunded_customer_sk
LEFT JOIN reason r
    ON wr_refund.wr_reason_sk = r.r_reason_sk
GROUP BY
    c_bill.c_customer_id,
    c_bill.c_first_name,
    c_bill.c_last_name,
    cd_bill.cd_gender,
    hd_bill.hd_buy_potential,
    t_sold.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
