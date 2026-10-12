WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sr.d_year AS return_year,
        cd.cd_gender,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_transactions,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_transactions,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_clos ON s.s_closed_date_sk = d_clos.d_date_sk
    JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_sr.d_year >= 2015
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, d_sr.d_year, cd.cd_gender
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.s_city,
    agg.return_year,
    agg.cd_gender,
    agg.store_return_transactions,
    agg.total_store_return_amount,
    agg.total_store_net_loss,
    agg.web_return_transactions,
    agg.total_web_return_amount,
    agg.total_web_net_loss,
    ROUND(
        CASE WHEN agg.total_store_return_amount = 0 THEN NULL
        ELSE agg.total_web_return_amount / agg.total_store_return_amount END,
        2
    ) AS web_to_store_return_ratio,
    agg.avg_purchase_estimate,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.total_store_net_loss DESC) AS store_rank
FROM agg
ORDER BY agg.total_store_net_loss DESC
LIMIT 100
