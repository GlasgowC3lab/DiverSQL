WITH promo_sales AS (
    SELECT
        p.p_promo_name,
        ca_bill.ca_country AS bill_country,
        ca_ship.ca_country AS ship_country,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_ship_cost,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_ext_ship_cost > 500
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    p.p_promo_name,
    ps.bill_country,
    ps.ship_country,
    COUNT(DISTINCT ps.cs_order_number) AS order_cnt,
    SUM(ps.cs_quantity) AS total_quantity,
    SUM(ps.cs_ext_sales_price) AS total_sales,
    SUM(ps.cs_ext_discount_amt) AS total_discount,
    SUM(ps.cs_ext_ship_cost) AS total_ship_cost,
    SUM(ps.cs_net_profit) AS total_net_profit,
    AVG(ps.cs_ext_discount_amt) AS avg_discount_amt,
    RANK() OVER (PARTITION BY ps.bill_country ORDER BY SUM(ps.cs_net_profit) DESC) AS profit_rank_in_bill_country
FROM promo_sales ps
JOIN promotion p ON ps.p_promo_name = p.p_promo_name
GROUP BY p.p_promo_name, ps.bill_country, ps.ship_country
HAVING SUM(ps.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
