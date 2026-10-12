WITH sampled_returns AS (
    SELECT
        wr_returned_time_sk,
        wr_reason_sk,
        wr_return_quantity,
        wr_net_loss
    FROM web_returns
    TABLESAMPLE BERNOULLI (10)
),
filtered_reason AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%price%'
       OR r_reason_desc LIKE '%color%'
),
excluded_reasons AS (
    SELECT r_reason_sk FROM reason
    EXCEPT
    SELECT DISTINCT wr_reason_sk FROM web_returns WHERE wr_net_loss > 1500
)
SELECT
    r.r_reason_desc,
    td.t_hour,
    td.t_minute,
    SUM(sr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(sr.wr_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(sr.wr_net_loss) > (SELECT AVG(wr_net_loss) FROM web_returns) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM sampled_returns sr
JOIN time_dim td ON sr.wr_returned_time_sk = td.t_time_sk
JOIN filtered_reason r ON sr.wr_reason_sk = r.r_reason_sk
WHERE td.t_minute IN (5, 10, 15)
  AND sr.wr_return_quantity > 0
  AND r.r_reason_sk IN (SELECT r_reason_sk FROM excluded_reasons)
GROUP BY r.r_reason_desc, td.t_hour, td.t_minute

UNION

SELECT
    r.r_reason_desc,
    td.t_hour,
    td.t_minute,
    SUM(sr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(sr.wr_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(sr.wr_net_loss) > (SELECT AVG(wr_net_loss) FROM web_returns) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM sampled_returns sr
JOIN time_dim td ON sr.wr_returned_time_sk = td.t_time_sk
JOIN filtered_reason r ON sr.wr_reason_sk = r.r_reason_sk
WHERE td.t_minute IN (1, 11)
  AND sr.wr_return_quantity > 1
  AND r.r_reason_sk IN (SELECT r_reason_sk FROM excluded_reasons)
GROUP BY r.r_reason_desc, td.t_hour, td.t_minute

ORDER BY total_net_loss DESC
LIMIT 100
