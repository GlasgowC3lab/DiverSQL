WITH store_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        COUNT(*) AS store_return_cnt,
        SUM(sr_return_amt) AS store_return_amt,
        SUM(sr_net_loss) AS store_net_loss,
        AVG(sr_return_quantity) AS store_avg_qty
    FROM store_returns
    WHERE sr_return_amt > 200
    GROUP BY sr_item_sk, sr_returned_date_sk
),
web_agg AS (
    SELECT
        wr_item_sk,
        wr_returned_date_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr_return_amt) AS web_return_amt,
        SUM(wr_net_loss) AS web_net_loss,
        AVG(wr_return_quantity) AS web_avg_qty
    FROM web_returns
    WHERE wr_return_amt > 200
    GROUP BY wr_item_sk, wr_returned_date_sk
)
SELECT
    COALESCE(s.sr_item_sk, w.wr_item_sk) AS item_sk,
    COALESCE(s.sr_returned_date_sk, w.wr_returned_date_sk) AS return_date_sk,
    COALESCE(s.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(w.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(s.store_return_amt, 0) AS store_return_amt,
    COALESCE(w.web_return_amt, 0) AS web_return_amt,
    COALESCE(s.store_net_loss, 0) AS store_net_loss,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    (COALESCE(s.store_return_amt, 0) + COALESCE(w.web_return_amt, 0)) AS total_return_amt,
    (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_net_loss,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) DESC) AS net_loss_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.sr_item_sk = w.wr_item_sk
    AND s.sr_returned_date_sk = w.wr_returned_date_sk
WHERE (COALESCE(s.store_return_amt, 0) + COALESCE(w.web_return_amt, 0)) > 500
ORDER BY total_net_loss DESC
LIMIT 100
