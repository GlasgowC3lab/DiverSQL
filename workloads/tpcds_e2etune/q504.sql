WITH aggregated_returns AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        cc.cc_call_center_id,
        cc.cc_market_manager,
        cc.cc_mkt_class,
        COUNT(DISTINCT sr.sr_customer_sk) AS store_customer_cnt,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS web_customer_cnt,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty,
        SUM(sr.sr_fee) + SUM(wr.wr_fee) AS total_fees
    FROM
        store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2005
        AND cc.cc_state = 'CA'
        AND cc.cc_mkt_class LIKE '%authori%'
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        cc.cc_call_center_id,
        cc.cc_market_manager,
        cc.cc_mkt_class
    HAVING
        SUM(sr.sr_return_amt) > 10000
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_name ORDER BY total_net_loss DESC) AS net_loss_rank
FROM
    aggregated_returns
ORDER BY
    total_net_loss DESC
LIMIT 100
