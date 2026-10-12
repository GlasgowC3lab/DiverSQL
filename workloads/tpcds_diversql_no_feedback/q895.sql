WITH
sales_a AS (
   SELECT
       cp.cp_department,
       w.w_warehouse_name,
       cs.cs_net_profit,
       cs.cs_quantity
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
   JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
   JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
   WHERE cp.cp_department = 'Sports'
     AND c.c_last_name = 'Morris'
     AND hd.hd_buy_potential = '1001-5000'
     AND t.t_shift = 'first'
     AND p.p_discount_active = 'Y'
     AND cd.cd_gender = 'M'
     AND cs.cs_quantity > 2
     AND cs.cs_net_profit > (
         SELECT avg(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_quantity > 5
     )
),

sales_b AS (
   SELECT
       cp.cp_department,
       w.w_warehouse_name,
       cs.cs_net_profit,
       cs.cs_quantity
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
   JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
   JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
   WHERE cp.cp_department = 'Clothing'
     AND c.c_last_name = 'Curtis'
     AND hd.hd_buy_potential = '501-1000'
     AND t.t_shift = 'second'
     AND p.p_discount_active = 'N'
     AND cd.cd_gender = 'F'
     AND cs.cs_quantity > 5
     AND cs.cs_net_profit > (
         SELECT avg(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_quantity > 5
     )
)
SELECT
    u.cp_department,
    u.w_warehouse_name,
    SUM(u.cs_net_profit) AS total_profit,
    COUNT(*) AS transaction_cnt,
    AVG(u.cs_net_profit) AS avg_profit
FROM (
    SELECT cp_department, w_warehouse_name, cs_net_profit, cs_quantity FROM sales_a
    UNION DISTINCT
    SELECT cp_department, w_warehouse_name, cs_net_profit, cs_quantity FROM sales_b
) u
GROUP BY u.cp_department, u.w_warehouse_name
HAVING AVG(u.cs_net_profit) > (
    SELECT avg(cs3.cs_net_profit)
    FROM catalog_sales cs3
    WHERE cs3.cs_quantity > 10
)
ORDER BY total_profit DESC
LIMIT 100
