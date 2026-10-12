WITH cs AS (
    SELECT
        cs_order_number,
        cs_ext_sales_price,
        cs_ext_tax,
        cs_net_profit,
        cs_sold_time_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_ship_cdemo_sk,
        cs_ship_hdemo_sk,
        cs_promo_sk
    FROM catalog_sales
),
ss AS (
    SELECT
        ss_ticket_number,
        ss_ext_sales_price,
        ss_ext_tax,
        ss_net_profit,
        ss_sold_time_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_promo_sk
    FROM store_sales
)
SELECT
    p.p_promo_name,
    td_sold.t_hour AS sale_hour,
    cd_bill.cd_gender,
    SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
    SUM(COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
    COUNT(DISTINCT COALESCE(cs.cs_order_number, ss.ss_ticket_number)) AS distinct_transactions,
    ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) DESC) AS rn
FROM cs
RIGHT OUTER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN time_dim td_sold
    ON cs.cs_sold_time_sk = td_sold.t_time_sk
LEFT JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN ss
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN time_dim td_store
    ON ss.ss_sold_time_sk = td_store.t_time_sk
LEFT JOIN customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
LEFT JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
WHERE p.p_channel_press = 'N'
  AND (cd_bill.cd_credit_rating = 'Good' OR cd_bill.cd_credit_rating = 'Low Risk')
GROUP BY
    p.p_promo_name,
    td_sold.t_hour,
    cd_bill.cd_gender
ORDER BY total_net_profit DESC
LIMIT 100
