SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_gender,
    cd_ship.cd_marital_status,
    cd_refunded.cd_gender,
    cd_returning.cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
