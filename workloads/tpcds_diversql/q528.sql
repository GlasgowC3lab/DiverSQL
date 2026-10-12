WITH
    -- First sub‑query: inner joins with filters and scalar sub‑query
    inner_agg AS (
        SELECT
            s.s_store_name AS store_name,
            cd.cd_gender   AS gender,
            SUM(sr.sr_return_amt) AS total_return_amt,
            AVG(sr.sr_fee)       AS avg_fee
        FROM   store s
        JOIN   store_returns sr
               ON s.s_store_sk = sr.sr_store_sk
        JOIN   customer_demographics cd
               ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE  s.s_state = 'CA'
          AND  sr.sr_fee > (SELECT MAX(sr2.sr_fee)
                           FROM   store_returns sr2
                           WHERE  sr2.sr_fee < 50)
        GROUP BY s.s_store_name, cd.cd_gender
    ),
    -- Second sub‑query: full outer join with sampling, EXISTS filter, and aggregation
    full_outer_agg AS (
        SELECT
            COALESCE(s.s_store_name, 'No Store') AS store_name,
            cd.cd_gender                     AS gender,
            SUM(sr.sr_return_amt)            AS total_return_amt,
            AVG(sr.sr_fee)                   AS avg_fee
        FROM   (SELECT * FROM store TABLESAMPLE BERNOULLI (10)) s
        FULL OUTER JOIN (SELECT * FROM store_returns TABLESAMPLE BERNOULLI (10)) sr
               ON s.s_store_sk = sr.sr_store_sk
        LEFT JOIN customer_demographics cd
               ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE  s.s_rec_end_date IS NOT NULL
          AND  s.s_rec_end_date > DATE '2000-01-01'
          AND  EXISTS (SELECT 1
                       FROM   store_returns sr2
                       WHERE  sr2.sr_store_sk = s.s_store_sk
                         AND  sr2.sr_net_loss > 100)
        GROUP BY COALESCE(s.s_store_name, 'No Store'), cd.cd_gender
    )
SELECT * FROM inner_agg
UNION ALL
SELECT * FROM full_outer_agg
LIMIT 100
