WITH store_return_agg AS (
    SELECT
        store.s_store_sk,
        store.s_store_name,
        DATE_FORMAT(date_dim.d_date, '%Y-%m') AS return_month,
        reason.r_reason_desc,
        regexp_extract(reason.r_reason_desc, '([A-Za-z]+)\\s+refund', 1) AS reason_keyword,
        CASE WHEN reason.r_reason_desc LIKE '%damaged%' THEN 'Damaged' ELSE 'Other' END AS reason_category,
        COUNT(*) AS returns_cnt,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN date_dim ON sr.sr_returned_date_sk = date_dim.d_date_sk
    JOIN store ON sr.sr_store_sk = store.s_store_sk
    JOIN reason ON sr.sr_reason_sk = reason.r_reason_sk
    WHERE regexp_like(reason.r_reason_desc, '.*refund.*')
      AND store.s_country = 'United States'
      AND date_dim.d_year = 2001
      AND store.s_store_sk NOT IN (
          SELECT sr2.sr_store_sk
          FROM store_returns sr2
          WHERE sr2.sr_return_quantity > 20
      )
    GROUP BY
        store.s_store_sk,
        store.s_store_name,
        DATE_FORMAT(date_dim.d_date, '%Y-%m'),
        reason.r_reason_desc,
        regexp_extract(reason.r_reason_desc, '([A-Za-z]+)\\s+refund', 1),
        CASE WHEN reason.r_reason_desc LIKE '%damaged%' THEN 'Damaged' ELSE 'Other' END
)
SELECT
    s_store_sk,
    s_store_name,
    return_month,
    reason_keyword,
    reason_category,
    returns_cnt,
    total_loss
FROM store_return_agg
ORDER BY total_loss DESC
LIMIT 100
