WITH store_agg AS (
    SELECT
        ca.ca_state,
        hd.hd_income_band_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        AVG(sr.sr_return_amt) AS avg_store_return_amt,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ca.ca_state, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        ca.ca_state,
        hd.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        AVG(wr.wr_return_amt) AS avg_web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ca.ca_state, hd.hd_income_band_sk
)
SELECT
    COALESCE(s.ca_state, w.ca_state) AS state,
    COALESCE(s.hd_income_band_sk, w.hd_income_band_sk) AS income_band,
    COALESCE(s.store_net_loss, 0) AS store_net_loss,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
    COALESCE(s.store_return_qty, 0) AS store_return_qty,
    COALESCE(w.web_return_qty, 0) AS web_return_qty,
    COALESCE(s.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(w.web_return_cnt, 0) AS web_return_cnt
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.ca_state = w.ca_state
   AND s.hd_income_band_sk = w.hd_income_band_sk
WHERE (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
