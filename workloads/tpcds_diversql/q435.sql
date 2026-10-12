WITH mode_stats AS (
   SELECT
       cs.cs_ship_mode_sk,
       sm.sm_ship_mode_id,
       avg(cs.cs_ext_discount_amt) AS avg_discount,
       sum(cs.cs_net_paid_inc_tax) AS total_net_paid
   FROM catalog_sales cs
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cs.cs_ship_mode_sk IN (
       SELECT sm2.sm_ship_mode_sk
       FROM ship_mode sm2
       WHERE sm2.sm_type = 'AIR'
   )
   GROUP BY cs.cs_ship_mode_sk, sm.sm_ship_mode_id
)
SELECT *
FROM (
   SELECT
       hd.hd_demo_sk AS demo_key,
       sm.sm_ship_mode_id AS ship_mode_id,
       cs.cs_net_paid_inc_tax AS net_paid,
       ms.avg_discount AS avg_discount,
       l.max_net_paid AS max_net_paid
   FROM catalog_sales cs
   JOIN household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN mode_stats ms
       ON cs.cs_ship_mode_sk = ms.cs_ship_mode_sk
   CROSS JOIN LATERAL (
       SELECT max(cs_inner.cs_net_paid_inc_tax) AS max_net_paid
       FROM catalog_sales cs_inner
       WHERE cs_inner.cs_ship_mode_sk = cs.cs_ship_mode_sk
   ) l
   WHERE cs.cs_net_paid_inc_tax > (
       SELECT avg(cs_sub.cs_net_paid_inc_tax)
       FROM catalog_sales cs_sub
       WHERE cs_sub.cs_ship_mode_sk = cs.cs_ship_mode_sk
   )
   AND EXISTS (
       SELECT 1
       FROM ship_mode sm_exist
       WHERE sm_exist.sm_contract = 'Ek'
         AND sm_exist.sm_ship_mode_sk = cs.cs_ship_mode_sk
   )
   UNION ALL
   SELECT
       hd.hd_demo_sk AS demo_key,
       NULL AS ship_mode_id,
       sum(ss.ss_net_paid) AS net_paid,
       avg(ss.ss_ext_discount_amt) AS avg_discount,
       NULL AS max_net_paid
   FROM store_sales ss
   JOIN household_demographics hd
       ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE ss.ss_net_paid > (SELECT avg(ss_sub.ss_net_paid) FROM store_sales ss_sub)
   GROUP BY hd.hd_demo_sk
) combined
ORDER BY demo_key, ship_mode_id NULLS LAST, net_paid DESC
OFFSET 0
LIMIT 100
