WITH
  catalog_sub AS (
    SELECT
      'catalog' AS channel,
      cp.cp_department AS entity,
      cs.cs_sold_date_sk AS sale_date_sk,
      cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_catalog_page_number >= 10
      AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
      AND p.p_discount_active = 'Y'
      AND cs.cs_net_paid > (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
      )
  ),
  store_sub AS (
    SELECT
      'store' AS channel,
      s.s_store_name AS entity,
      ss.ss_sold_date_sk AS sale_date_sk,
      ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
      AND p.p_discount_active = 'Y'
      AND ss.ss_net_paid > (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
      )
  ),
  unioned AS (
    SELECT channel, entity, sale_date_sk, net_paid FROM catalog_sub
    UNION ALL
    SELECT channel, entity, sale_date_sk, net_paid FROM store_sub
  )
SELECT
  channel,
  entity,
  sale_date_sk,
  SUM(net_paid) AS total_net_paid
FROM unioned
GROUP BY GROUPING SETS (
  (channel, entity),
  (sale_date_sk),
  ()
)
ORDER BY total_net_paid DESC
LIMIT 100
