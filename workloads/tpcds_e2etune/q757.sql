WITH catalog_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        td.t_hour,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM call_center cc
    JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_tax_percentage > 0.05
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_call_center_sk, cc.cc_name, td.t_hour
),
store_agg AS (
    SELECT
        td.t_hour,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY td.t_hour
),
web_agg AS (
    SELECT
        td.t_hour,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY td.t_hour
)
SELECT
    ca.cc_call_center_sk,
    ca.cc_name,
    ca.t_hour,
    ca.catalog_net_loss,
    sa.store_net_loss,
    wa.web_net_loss,
    (COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    RANK() OVER (PARTITION BY ca.t_hour ORDER BY (COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS rank_within_hour
FROM catalog_agg ca
LEFT JOIN store_agg sa ON ca.t_hour = sa.t_hour
LEFT JOIN web_agg wa ON ca.t_hour = wa.t_hour
WHERE (COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) > 0
ORDER BY total_net_loss DESC
LIMIT 100
