WITH sales_agg AS (
   SELECT
       p.p_promo_id,
       s.s_store_name,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
   JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN web_returns wr ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
     AND cs.cs_ext_tax > 10
     AND ca.ca_country = 'United States'
     AND p.p_discount_active = 'Y'
   GROUP BY CUBE(p.p_promo_id, s.s_store_name)
), ranked AS (
   SELECT
       p_promo_id,
       s_store_name,
       total_net_paid,
       total_net_profit,
       sales_cnt,
       ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_paid DESC) AS rn
   FROM sales_agg
)
SELECT
    r.p_promo_id,
    r.s_store_name,
    r.total_net_paid,
    r.total_net_profit,
    r.sales_cnt,
    r.rn,
    grp.grp_id
FROM ranked r
CROSS JOIN (SELECT 1 AS grp_id UNION ALL SELECT 2 AS grp_id) grp
WHERE r.rn <= 5
ORDER BY r.total_net_paid DESC
OFFSET 0 LIMIT 100
