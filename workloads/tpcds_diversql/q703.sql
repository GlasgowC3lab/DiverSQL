WITH cs_demo AS (
   SELECT DISTINCT cs.cs_bill_cdemo_sk AS cd_demo_sk
   FROM catalog_sales cs
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_gender = 'M'
),
sr_demo AS (
   SELECT DISTINCT sr.sr_cdemo_sk AS cd_demo_sk
   FROM store_returns sr
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_marital_status = 'M'
),
-- Customers present in catalog sales but not in store returns
demo_excluded AS (
   SELECT cd_demo_sk FROM cs_demo
   EXCEPT
   SELECT cd_demo_sk FROM sr_demo
),
-- Customers present in both catalog sales and store returns
demo_common AS (
   SELECT cd_demo_sk FROM cs_demo
   INTERSECT
   SELECT cd_demo_sk FROM sr_demo
),
-- Full outer join between stores and their returned sales, keeping unmatched rows on either side
store_demo_returns AS (
   SELECT s.s_store_id,
          cd.cd_demo_sk,
          sr.sr_return_amt,
          (
             SELECT SUM(cs.cs_net_paid)
             FROM catalog_sales cs
             WHERE cs.cs_bill_cdemo_sk = cd.cd_demo_sk
          ) AS total_catalog_net_paid
   FROM store s
   FULL OUTER JOIN (
      SELECT sr.sr_store_sk, sr.sr_cdemo_sk, sr.sr_return_amt
      FROM store_returns sr
   ) sr ON s.s_store_sk = sr.sr_store_sk
   LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
)
SELECT sdr.s_store_id,
       sdr.cd_demo_sk,
       sdr.sr_return_amt,
       sdr.total_catalog_net_paid
FROM store_demo_returns sdr
WHERE sdr.cd_demo_sk IN (SELECT cd_demo_sk FROM demo_common)

UNION ALL

SELECT CAST(NULL AS VARCHAR) AS s_store_id,
       de.cd_demo_sk,
       CAST(NULL AS DECIMAL(7,2)) AS sr_return_amt,
       (
          SELECT SUM(cs.cs_net_paid)
          FROM catalog_sales cs
          WHERE cs.cs_bill_cdemo_sk = de.cd_demo_sk
       ) AS total_catalog_net_paid
FROM demo_excluded de
