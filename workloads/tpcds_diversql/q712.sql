WITH RECURSIVE reason_path(reason_sk, level) AS (
    SELECT r.r_reason_sk, 1
    FROM reason r
    WHERE r.r_reason_desc LIKE '%damage%'
    UNION ALL
    SELECT sr.sr_reason_sk, rp.level + 1
    FROM reason_path rp
    JOIN store_returns sr ON sr.sr_reason_sk = rp.reason_sk
    WHERE rp.level < 3
)
SELECT *
FROM (
    SELECT ca.ca_address_id,
           cd.cd_gender,
           SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN reason_path rp ON rp.reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 100
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_quantity > 0
      )
    GROUP BY ca.ca_address_id, cd.cd_gender
) AS a
INTERSECT
SELECT *
FROM (
    SELECT ca.ca_address_id,
           cd.cd_gender,
           SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    FULL OUTER JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    FULL OUTER JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 100
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_reason_sk = r.r_reason_sk
            AND sr2.sr_return_amt > 0
      )
    GROUP BY ca.ca_address_id, cd.cd_gender
) AS b
LIMIT 100
