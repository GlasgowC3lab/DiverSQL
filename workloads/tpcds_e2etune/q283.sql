WITH catalog_agg AS (
    SELECT cr_returned_date_sk AS date_sk,
           SUM(cr_return_amt_inc_tax) AS cat_return_inc_tax,
           SUM(cr_fee) AS cat_fee_total,
           SUM(cr_net_loss) AS cat_net_loss,
           COUNT(*) AS cat_return_cnt
    FROM catalog_returns
    WHERE cr_fee > 20
      AND cr_return_quantity > 5
    GROUP BY cr_returned_date_sk
),
store_agg AS (
    SELECT sr_returned_date_sk AS date_sk,
           SUM(sr_return_amt_inc_tax) AS store_return_inc_tax,
           SUM(sr_fee) AS store_fee_total,
           SUM(sr_net_loss) AS store_net_loss,
           COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_fee > 20
      AND sr_return_quantity > 5
    GROUP BY sr_returned_date_sk
),
web_agg AS (
    SELECT wr_returned_date_sk AS date_sk,
           SUM(wr_return_amt_inc_tax) AS web_return_inc_tax,
           SUM(wr_fee) AS web_fee_total,
           SUM(wr_net_loss) AS web_net_loss,
           COUNT(*) AS web_return_cnt
    FROM web_returns
    WHERE wr_fee > 20
      AND wr_return_quantity > 5
    GROUP BY wr_returned_date_sk
)
SELECT
    COALESCE(c.date_sk, s.date_sk, w.date_sk) AS returned_date_sk,
    COALESCE(c.cat_return_inc_tax, 0) AS cat_return_inc_tax,
    COALESCE(s.store_return_inc_tax, 0) AS store_return_inc_tax,
    COALESCE(w.web_return_inc_tax, 0) AS web_return_inc_tax,
    (COALESCE(c.cat_return_inc_tax, 0) + COALESCE(s.store_return_inc_tax, 0) + COALESCE(w.web_return_inc_tax, 0)) AS total_return_inc_tax,
    ROUND((COALESCE(c.cat_return_inc_tax, 0) / NULLIF((COALESCE(c.cat_return_inc_tax, 0) + COALESCE(s.store_return_inc_tax, 0) + COALESCE(w.web_return_inc_tax, 0)), 0)) * 100, 2) AS cat_share_pct,
    ROUND((COALESCE(s.store_return_inc_tax, 0) / NULLIF((COALESCE(c.cat_return_inc_tax, 0) + COALESCE(s.store_return_inc_tax, 0) + COALESCE(w.web_return_inc_tax, 0)), 0)) * 100, 2) AS store_share_pct,
    ROUND((COALESCE(w.web_return_inc_tax, 0) / NULLIF((COALESCE(c.cat_return_inc_tax, 0) + COALESCE(s.store_return_inc_tax, 0) + COALESCE(w.web_return_inc_tax, 0)), 0)) * 100, 2) AS web_share_pct,
    COALESCE(c.cat_fee_total, 0) + COALESCE(s.store_fee_total, 0) + COALESCE(w.web_fee_total, 0) AS total_fee,
    COALESCE(c.cat_net_loss, 0) + COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
    COALESCE(c.cat_return_cnt, 0) + COALESCE(s.store_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
    RANK() OVER (ORDER BY (COALESCE(c.cat_return_inc_tax, 0) + COALESCE(s.store_return_inc_tax, 0) + COALESCE(w.web_return_inc_tax, 0)) DESC) AS return_day_rank
FROM catalog_agg c
FULL OUTER JOIN store_agg s ON c.date_sk = s.date_sk
FULL OUTER JOIN web_agg w ON COALESCE(c.date_sk, s.date_sk) = w.date_sk
WHERE (COALESCE(c.cat_return_inc_tax, 0) + COALESCE(s.store_return_inc_tax, 0) + COALESCE(w.web_return_inc_tax, 0)) > 1000
ORDER BY total_return_inc_tax DESC
LIMIT 100
